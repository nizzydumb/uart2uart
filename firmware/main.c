#define UART_POLLING

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <irq.h>

#include <libbase/uart.h>
#include <libbase/console.h>
#include <generated/csr.h>
#include <generated/mem.h>



static inline int uart_prompt_rx_ready(void)
{
    return uart_prompt_rxempty_read() == 0;
}

static inline uint8_t uart_prompt_getchar(void)
{
    char c = uart_prompt_rxtx_read();
    uart_prompt_ev_pending_write(UART_EV_RX);
    return (uint8_t)c;
}

void uart_prompt_write(char c)
{
	while (uart_prompt_txfull_read());
	uart_prompt_rxtx_write(c);
	uart_prompt_ev_pending_write(UART_EV_TX);
}

void uart_prompt_init()
{
   	uart_prompt_ev_pending_write(uart_prompt_ev_pending_read());
   	uart_prompt_ev_enable_write(UART_EV_TX | UART_EV_RX);
}

static void put_hex8(void (*put)(char), uint8_t v)
{
    const char h[] = "0123456789ABCDEF";
    put(h[v >> 4]);
    put(h[v & 0x0F]);
}

static void put_dec3(void (*put)(char), uint8_t v)
{
    if (v >= 100) 
    { 
    	put('0' + v/100);        
    	v %= 100; 
    } else 
    { 
    	put(' '); 
    }
    put('0' + v/10);
    put('0' + v%10);
}

static inline void put_nl(void (*put)(char))
{
    put('\r');
    put('\n');
}

void uart_to_uart_bridge(int (*rx_ready)(void), uint8_t (*get_byte)(void), void (*put_char)(char))
{
    if (!rx_ready())                   
        return;

    uint8_t len = get_byte();
    uint8_t buf[255];

    for (int i = 0; i < len; ++i) 
    {	
    	while(!rx_ready());
        buf[i] = get_byte();          
	}

    put_nl(put_char);
    put_char('f'); put_char('r'); put_char('a'); put_char('m'); put_char('e'); put_char(' '); put_char('l'); put_char('e'); put_char('n'); put_char('='); put_char(' ');
    put_dec3(put_char, len);
    put_nl(put_char);
        
    for (uint8_t i = 0; i < len; ++i) {
        if ((i & 0x0F) == 0) put_nl(put_char);  
        put_hex8(put_char, buf[i]);
        put_char(' ');
    }
    put_nl(put_char);

    
}

int main(void) {
    irq_setmask(0);
    irq_setie(1);	
    uart_init(); 
    uart_prompt_init();

   	printf("UART-UART bridge started!\n");
   	
    while (1) 
    {	
    	uart_to_uart_bridge(uart_prompt_rx_ready, uart_prompt_getchar, uart_write); // uart_prompt to serial bridge
    }

    return 0;

}

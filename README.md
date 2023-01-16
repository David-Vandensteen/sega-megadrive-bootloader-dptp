# sega-megadrive-bootloader-dptp  
I wrote this bootloader for the development of this flaschard.  
https://www.youtube.com/watch?v=M0YR9CBihXw  
  
The second goal was to learn ASM68K

This assembly language code is a bootloader for the Sega Genesis game console.  
It defines a set of macros and interrupt vectors for initializing and configuring the system.  
It also served as a learning tool to understand the capabilities of the 68000 processor and the Sega Genesis console.  

## Macros
  - align: Inserts a CNOP instruction with an operand of the specified value.
  - Disable_Ints: Disables interrupts by setting the status register to $2700.
  - Enable_Ints: Enables interrupts by setting the status register to $2000.
  - VDP_W_Vram: Writes a 32-bit value to video RAM at the specified address and stores the result in the specified destination register.
  - VDP_W_Cram: Writes a 32-bit value to color RAM at the specified address and stores the result in the specified destination register.
  - VDP_W_Vsram: Writes a 32-bit value to sprite attribute RAM at the specified address and stores the result in the specified destination register.

## Interrupt Vectors

The code also defines a set of interrupt vectors for the 68000 microprocessor.  
These vectors handle various types of exceptions, including bus error, address error, illegal instruction, division by zero, and IRQs.

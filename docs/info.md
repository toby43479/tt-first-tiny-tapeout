## How it works

This is a simple IO expander that can be configured over I2C.

It can:
- read the input pins
- set the output pins to fixed values
- set the output pins to a PWM output
- set the output pins to an OR of select input pins
- read a (short) PWM input signal

The I2C takes place over bidirectional pins 0 and 1.  All other input/output refers to the unidirectional pins.

It responds to address 0x52 (so the first byte is 0xA4 for write, and 0xA5 for read).  All bytes are treated as big-endian, bit 7 is sent first.

The first written byte after the address selects which register(s) to use, and all following reads or writes will use this register.  To select a different register, a stop has to be sent.  Restarts will continue from the previously set register, as will read transactions with no write.

There are 16 registers, and bits 0-3 of the register select byte are used to select one.  Bits 4-6 are unused and ignored.  Bit 7 is an auto-increment flag;  if 1, the register number increments after each read or write.  All registers are set to 0 on reset.

Registers:
0: Read-only register than returns the current state of the input pins.  Writes are ignored.
1: Read/write default pin state configuration.  If a pin has no other output option selected, it will be set by this register.
2: Read/write OR input selector.  Bitmask to select which pins will be ORed together.
3: Read/write OR output selector.  Bitmask to select which pins the OR result will be output to.
4/5/6: 8-bit PWM.
4: Read/write period time;  counter will reset every n clock cycles.
5: Read/write duty cycle setting;  PWM output is low until counter hits n, and high afterwards.
6: Read/write output pin mask.  Select which pins will receive the PWM output.
7: Read/write noop register.
8: Read/write noop register.
9: Read/write noop register.
10: Read/write PWM input pin mask.
11: Read-only high time duty cycle.  Counts how many of the last 'hff cycles had any of the inputs high.
12: Read-only low time duty cycle.  Counts how many of the last 'hff cycles had any of the inputs low.
13: Read-only detected cycle time.  Time between the last two rising edges of the input.
14: Read/write noop register.
15: Read/write noop register.

## How to test

You need a device that can send I2C commands.  Connect via I2C over bidirectional pins 0 and 1.  0 is SCL and 1 is SDA.

Example: START 0xA4 0x00 RESTART 0xA5 0x.. STOP
Reads register 0.  The byte read will be the state of the input pins.
Continuing to read instead of sending STOP will continuously recapture the state of the pins.

Example: START 0xA4 0x01 0x55 STOP
Sets register 1 to 0x55.  Sets output pins 0, 2, 4, 6 high, and pins 1, 3, 5, 7 low.

Example: START 0xA4 0x84 0xFF 0x7F 0x01 STOP
Sets register 4 to 0xFF, 5 to 0x7F and 6 to 0x01.  Sets output pin 0 to a 50% duty cycle PWM signal.

Example: START 0xA4 0x82 0xF0 0x02 STOP
Sets register 2 to 0xF0 and 3 to 0x02.  Sets output pin 1 to the OR of input pins 4, 5, 6, and 7.

Example: START 0xA4 0x0A 0x04 STOP
Sets register 10 to 0x04.  Enables PWM input on input pin 2.
Wait for 256 clock cycles to pass, then: START 0xA4 0x8B RESTART 0xA5 0x.. 0x.. 0x.. STOP
Reads from registers 11, 12, and 13.  Read the high time, low time and wavelength of input pin 2.

## External hardware

You need a device that can send I2C commands to control it.

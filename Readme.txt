# RC5 Encryption/Decryption Implementation in AVR Assembly

## Project Overview

This project implements the RC5 encryption algorithm in AVR assembly language for the ATmega328P microcontroller. The implementation includes complete encryption and decryption capabilities with output display via an LCD interface. The system demonstrates secure data encryption using a configurable secret key.

## Technology and Components

### Hardware Requirements
- ATmega328P microcontroller
- 16x2 LCD display (interfaced via Port D for data and Port B for control)
- Proteus simulation environment for testing
- Crystal oscillator (clock source)

### Software Components
- Written in AVR Assembly language
- Developed in Atmel Studio 7.0
- Simulated in Proteus

## RC5 Algorithm Overview

RC5 (Rivest Cipher 5) is a symmetric block cipher designed by Ronald Rivest in 1994. This implementation uses:

- **Word size (W)**: 16 bits
- **Number of rounds (R)**: 8
- **Key size**: 12 bytes (96 bits)
- **Block size**: 32 bits (2 words)
- **Expanded key table size (T)**: 18 words

### Key Algorithm Constants
```
PL = 0xE1, PH = 0xB7 (P = 0xB7E1, derived from e)
QL = 0x37, QH = 0x9E (Q = 0x9E37, derived from golden ratio φ)
```

## Implementation Details

### Memory Organization
The project uses SRAM for:
- Secret key storage (addresses 0x0200-0x020B)
- Expanded key table (S array) storage (starting at 0x0210)
- L array storage (starting at 0x0220)

### Key Expansion Process
1. Initialize S[0] with constant P (0xB7E1)
2. Initialize subsequent elements of S using Q (0x9E37) in an arithmetic progression
3. Mix in the secret key to create a pseudo-random expanded key table

### Encryption Process
1. Add initial values of S[0] and S[1] to the input words A and B
2. For each round (R=8):
   - XOR A with B
   - Rotate A left by (B mod 16) bits
   - Add a subkey value from S to A
   - XOR B with A
   - Rotate B left by (A mod 16) bits
   - Add a subkey value from S to B

### Decryption Process
1. For each round (R=8) in reverse order:
   - Subtract a subkey value from B
   - Rotate B right by (A mod 16) bits
   - XOR B with A
   - Subtract a subkey value from A
   - Rotate A right by (B mod 16) bits
   - XOR A with B
2. Subtract initial values of S[0] and S[1] from A and B

### Word Operations
The implementation includes custom macros for:
- `ROTL_WORD`: Rotate left operation for 16-bit words
- `ROTR_WORD`: Rotate right operation for 16-bit words
- `XOR_WORD`: Bitwise XOR of two 16-bit words
- `ADD_WORD`: Addition of two 16-bit words
- `SUB_WORD`: Subtraction of two 16-bit words

## Usage and Test Cases

The project demonstrates encryption and decryption using two test cases:
1. The string "Kemo" (represented as the hexadecimal values 0x4B65, 0x6D6F)
2. The string "0080" (represented as the hexadecimal values 0x3030, 0x3830)

For each test case, the program:
1. Displays the original plaintext
2. Encrypts and displays the ciphertext
3. Decrypts and displays the recovered plaintext

## Proteus Simulation

The included Proteus simulation file provides a complete virtual testing environment with:
- ATmega328P microcontroller configuration
- LCD interface connection
- Visual representation of encryption/decryption results

## Security Considerations

This implementation uses:
- A configurable 96-bit secret key (default: zeros with one byte set to 0x50)
- 8 rounds of encryption/decryption
- Standard RC5 key expansion for diffusion

## References and Resources

- Rivest, R. (1994). "The RC5 encryption algorithm"
- Atmel ATmega328P datasheet
- AVR Instruction Set Manual

---

*Note: The project demonstrates RC5 for educational purposes. For production security applications, consider using standardized implementations of current encryption standards.*
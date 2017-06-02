; Optimized unprotected implementation of DoubleKing: Baseking with 32-bit words.
; Author: Tim van Dijk

; === KEY ADDITION ENC ===
	MACRO
$label AddKey
	ldr r13, =key
	
	ldr r12, [r13]
	ldr r14, [r13, #4]!
	eor r0, r12, r0, ror #2
	eor r1, r14, r1, ror #23
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r2, r12, r2
	eor r3, r14, r3
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r4, r12, r4, ror #28
	eor r5, r14, r5, ror #21
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r6, r12, r6, ror #15
	eor r7, r14, r7, ror #10
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r8, r12, r8
	eor r9, r14, r9
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r10, r12, r10, ror #1
	eor r11, r14, r11
	MEND

	MACRO
$label KeyAdditionEncryption
	; Requires the rc to be in r14.
	; The order in which we xor doesnt matter (as long as we shift first),
	; so we add the rc first, such that r14 is free again.
	eor r2, r14, r2, ror #13
	eor r3, r14, r3, ror #4
	eor r8, r14, r8, ror #6
	eor r9, r14, r9, ror #3
	AddKey
	MEND

	MACRO
$label AddKeyNoLateShift
	ldr r13, =key
	
	ldr r12, [r13]
	ldr r14, [r13, #4]!
	eor r0, r12, r0
	eor r1, r14, r1
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r2, r12, r2
	eor r3, r14, r3
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r4, r12, r4
	eor r5, r14, r5
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r6, r12, r6
	eor r7, r14, r7
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r8, r12, r8
	eor r9, r14, r9
	
	ldr r12, [r13, #4]!
	ldr r14, [r13, #4]!
	eor r10, r12, r10
	eor r11, r14, r11
	MEND

	MACRO
$label KeyAdditionEncryptionNoLateShift
	; Requires the rc to be in r14
	; This version is not combined with the late shift. We need this in the first round.
	; The order in which we xor doesnt matter, so we add the rc first, such that r14 is free again.
	eor r2, r2, r14
	eor r3, r3, r14
	eor r8, r8, r14
	eor r9, r9, r14
	AddKeyNoLateShift
	MEND

; === DIFFUSION ===
	MACRO
$label Diffusion
	; First we compute r0 xor r1 xor ... xor r11 and store it in r12.
	; We will use this in computing a6-a11.
	eor r12, r0, r1
	eor r12, r2
	eor r12, r3
	eor r12, r4
	eor r12, r5
	eor r12, r6
	eor r12, r7
	eor r12, r8
	eor r12, r9
	eor r12, r10
	eor r12, r11
	; Save it to SRAM, because we really need r12 in order to avoid further use of memory.
	; Also store a0-a5, thus r0-r5, because we will need it later as well.
	ldr r13, =xor_and_state
	
	; stm stores as little endian, which I think is inconvenient, so I will do it manually. 
	; stm r13, {r0-r5,r12}
	str r0, [r13]
	str r1, [r13, #4]
	str r2, [r13, #8]
	str r3, [r13, #12]
	str r4, [r13, #16]
	str r5, [r13, #20]
	str r12, [r13, #24]

	;Save a0 in r14 because we will need it later
	mov r14, r0
	
	; Registers: r0: a0; r12: -; r14: a0
	; Compute a0' = a0 xor a2 xor a6 xor a7 xor a9 xor a10 xor a11.
	eor r0, r2
	eor r0, r6
	eor r0, r7
	eor r0, r10
	
	; We store a9 xor a11 in r12 such that save one cycle when computing a3'.
	eor r12, r9, r11
	
	eor r0, r12
	; Finished computing a0'.

	; As it turns out, we can't use r13 in eor operations.
	; Therefore we need another register.
	; We free r0 by storing a0' to SRAM.
	ldr r13, =saved_word
	str r0, [r13]

	; Store a0 in r0
	mov r0, r14

	; Store a0 xor a1 in r14
	eor r14, r0, r1

	; Registers: r0: a0; r12: a9 xor a11; r14: a0 xor a1	
	; Compute a1' = a0 xor a1 xor a3 xor a7 xor a8 xor a10 xor a11.
	eor r1, r0
	eor r1, r3
	eor r1, r7
	eor r1, r8
	eor r1, r10
	eor r1, r11
	; Finished computing a1'.
	
	; Store a0 xor a1 xor a2 in r14
	eor r14, r2
		
	; Registers: r0: a0; r12: a9 xor a11; r14: a0 xor a1 xor a2
	; Compute a2' = a0 xor a1 xor a2 xor a4 xor a8 xor a9 xor a11.
	eor r2, r14, r12
	eor r2, r4
	eor r2, r8
	; Finished computing a2'.
	
	; Store a3 xor a11 in r12
	eor r12, r3, r11
	
	; Registers: r0: a0; r12: a3 xor a11; r14: a0 xor a1 xor a2
	; Compute a3' = a0 xor a1 xor a2 xor a3 xor a5 xor a9 xor a10.
	eor r3, r14
	eor r3, r5
	eor r3, r9
	eor r3, r10
	; Finished computing a3'.
	
	; Store a0 xor a1 xor a2 xor a3 xor a4 xor a11 in r14
	eor r14, r12
	eor r14, r4
	
	; Registers: r0: a0; r12: a3 xor a11; r14: a0 xor a1 xor a2 xor a3 xor a4 xor a11	
	; Compute a4' = a1 xor a2 xor a3 xor a4 xor a6 xor a10 xor a11.
	eor r4, r14, r0
	eor r4, r6
	eor r4, r10
	; Finished computing a4'.
	
	; Registers: r0: a0; r12: a3 xor a11; r14: a0 xor a1 xor a2 xor a3 xor a4 xor a11
	; Compute a5' = a0 xor a2 xor a3 xor a4 xor a5 xor a7 xor a11.
	eor r5, r14
	eor r5, r7
	; We now have r5 = a5' xor a1
	; We need to retrieve a1 soon anyway to compute ???, so it's not too bad. 
	
	; I found that the following relation holds:
	; ai+6' = ai+6 xor ai xor ai' xor (a0 xor ... xor a11)
	; We make use of that to compute a6' to a11'.
	
	; We still have a0 in r0, which we need to compute a10'.
	; Store a10 in r14 because we need a10 to compute a8'.
	mov r14, r10
	eor r6, r0
	
	; Retrieve a0' from SRAM.
	ldr r13, =saved_word
	ldr r0, [r13]
	; Finished computing a0'
	
	; Get the xor of everything back in r12.
	ldr r13, =xor_and_state	
	ldr r12, [r13, #24]
	
	; We xor a6-a11 right away such r12 is free and we can pipeline two ldr instructions.
	eor r6, r12
	eor r7, r12
	eor r8, r12
	eor r9, r12
	eor r10, r12
	eor r11, r12
	
	; a6' = a6 xor a0' xor a0 xor ALL
	; Currently in r6 is: a6 xor a0 xor ALL
	eor r6, r0
	; Finished computing a6'.
	
	; Load a1 into r12 and a2 into r14
	ldr r12, [r13, #4]
	ldr r14, [r13, #8]
	
	; Now that we have a1 in r12, we can finish computing a5'.
	eor r5, r12
	; Finished computing a5'.
	
	; a7' = a7 xor a1' xor a1 xor ALL
	; Currently in r7 is: a7 xor ALL
	eor r7, r1
	eor r7, r12
	; Finished computing a7'.
	
	; a8' = a8 xor a2' xor a2 xor ALL
	; Currently in r8 is: a8 xor ALL
	eor r8, r2
	eor r8, r14
	; Finished computing a8'.
	
	; Load a3 into r12 and a4 into r14
	ldr r12, [r13, #12]
	ldr r14, [r13, #16]
	
	; a9' = a9 xor a3' xor a3 xor ALL
	; Currently in r9 is: a9 xor ALL
	eor r9, r3
	eor r9, r12
	; Finished computing a9'.
	
	; a10' = a10 xor a4' xor a4 xor ALL
	; Currently in r10 is: a10 xor ALL
	eor r10, r4
	eor r10, r14
	; Finished computing a10'.
	
	; Load a5 into r12 
	ldr r12, [r13, #20]
	
	; a11' = a11 xor a5' xor a5 xor ALL
	; Currently in r11 is: a11 xor ALL
	eor r11, r5
	eor r11, r12
	; Finished computing a11'.
	MEND

; === S-BOX ===
	MACRO
$label SBoxPart $arg0, $arg1, $arg2, $rot0, $rot1, $rot2
	mvn r12, $arg2, ror $rot2
	orr r12, r12, $arg1, ror $rot1
	mov r14, $arg0, ror $rot0
	eor $arg0, r12, r14 ; finishes setting $arg0
	
	mvn r12, r14
	orr r12, r12, $arg2, ror $rot2
	eor $arg1, r12, $arg1, ror $rot1 ; finishes setting $arg1 
	
	mvn r12, r12
	eor r12, $arg1, r12
	orr r12, r14, r12
	eor $arg2, r12, $arg2, ror $rot2 ; finishes setting $arg2
	MEND
	
	MACRO
$label SBoxPartAlt $arg0, $arg1, $arg2, $rot1, $rot2
	;We can't do ror #0, so this version just leaves that part out.
	mvn r12, $arg2, ror $rot2
	orr r12, r12, $arg1, ror $rot1
	mov r14, $arg0
	eor $arg0, r12, r14 ; finishes setting $arg0
	
	mvn r12, r14
	orr r12, r12, $arg2, ror $rot2
	eor $arg1, r12, $arg1, ror $rot1 ; finishes setting $arg1 
	
	mvn r12, r12
	eor r12, $arg1, r12
	orr r12, r14, r12
	eor $arg2, r12, $arg2, ror $rot2 ; finishes setting $arg2
	MEND
	
	MACRO
$label SBox
	SBoxPartAlt r0, r4, r8, #22, #28
	SBoxPart r1, r5, r9, #31, #17, #19
	SBoxPart r2, r6, r10, #29, #11, #9
	SBoxPart r3, r7, r11, #26, #4, #30
	MEND

; === REVERSE STATE ===
	MACRO
$label Swap $arg0, $arg1
	eor $arg0, $arg0, $arg1
	eor $arg1, $arg0, $arg1
	eor $arg0, $arg0, $arg1
	MEND
	
	MACRO
$label ReverseState
	Swap r0, r11
	Swap r1, r10
	Swap r2, r9
	Swap r3, r8
	Swap r4, r7
	Swap r5, r6
	MEND

	AREA data, DATA, READONLY
pt dcd 0x9a2b5444, 0x5627cb9f, 0x5ba357fb, 0x0b96c880, 0x948c9d0d, 0xe5df2a69, 0x93987934, 0x33ba2528, 0xaee480a4, 0x01205381, 0x561b7143, 0xb3b6c8c2
key dcd 0x2c78b512, 0x708c5206, 0x1506efa0, 0x49a18d03, 0x35056fe2, 0x09c58df2, 0xdfd181a4, 0x35e11184, 0x406f62ce, 0x0b4a8430, 0x78455668, 0x1b282415
rc dcd 11, 22, 44, 88, 176, 113, 226, 213, 187, 103, 206, 141

	AREA globalvars, DATA, READWRITE
round_nr dcd 0
xor_and_state dcd 0, 0, 0, 0, 0, 0, 0
saved_word dcd 0

	AREA code, CODE
	ENTRY
	EXPORT __main
	
__main

init
	; We start by loading the hardcoded plaintext into registers r0 to r11.
	ldr r12, =pt
	ldm r12, {r0-r11}
	; We dont need to move the key because we will retrieve it from memory when necessary.
	
	; BaseKing has 11 rounds...
first_round
	; In this round we need to use a different key addition macro because
	; the normal key addition macro is combined with the late shift of the previous round
	; r14 must contain the round constant. For round 0 it is 11
	mov r14, #11
	KeyAdditionEncryptionNoLateShift
	Diffusion
	SBox
	
loop_setup
	; r12 contains the number of the round (times 4).
	mov r12, #4 ; not 0 but 1*4 because we are about to enter round 1.

round
	;Load the round constant for this round into r14.
	ldr r14, =rc
	ldr r14, [r14, r12]
	
	;Store r12, the round number (multiplied by 4), to SRAM such that we have third register to work with.
	ldr r13, =round_nr
	str r12, [r13]
	
	KeyAdditionEncryption ; LateShift + KeyAdditionEncryption.
	Diffusion
	SBox ; SBox + EarlyShift.

	; Retrieve r12, the round number, from SRAM.
	ldr r14, =round_nr
	ldr r12, [r14]
	
	; Increment counter.
	add r12, #4
	
	; Check if ready to proceed to final round (11*4=44).
	cmp r12, #44
	blt round

final_round
	; And 1 final output transformation.
	; The round constant for this round is 141
	mov r14, #141
	KeyAdditionEncryption ; LateShift + KeyAdditionCryption
	Diffusion
	ReverseState
	
end
	b end
		
	END
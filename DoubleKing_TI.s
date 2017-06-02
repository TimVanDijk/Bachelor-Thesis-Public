; Optimized threshold implementation of DoubleKing: Baseking with 32-bit words.
; Author: Tim van Dijk

	MACRO
$label CreateShares
	; We start by splitting the state into 3 shares
	; in_0 = rand_0
	; in_1 = rand_1
	; in_2 = pt xor rand_0 xor rand_1
	; in_0 xor in_1 xor in_2 = rand_0 xor rand_1 xor pt xor rand_0 xor rand_1 = pt

	; Retrieve first half of pt and first half of rand_0 from memory.
	ldr r12, =pt
	ldr r13, =rand_0
	ldm r12, {r0-r5}
	ldm r13, {r6-r11}
	
	; xor the first half of rand_0 with the first half of pt.
	eor r0, r6
	eor r1, r7
	eor r2, r8
	eor r3, r9
	eor r4, r10
	eor r5, r11
	
	; Store first half of rand_0 to the first half of in_0.
	ldr r12, =in_0
	stm r12, {r6-r11}

	; Retrieve the first half of rand_1 from memory.
	ldr r12, =rand_1
	ldm r12, {r6-r11}
	
	; xor the first half of rand_1 with the first half of pt xor rand_0.
	eor r0, r6
	eor r1, r7
	eor r2, r8
	eor r3, r9
	eor r4, r10
	eor r5, r11
	
	; Store the first half of rand_1 to the first half of in_1.
	ldr r12, =in_1
	stm r12, {r6-r11}
	
	; r0-r5 contains the first half of in_2. Write it to memory.
	ldr r12, =in_2
	stm r12, {r0-r5}
	
	; Repeat but for the second halves.
	; The syntax does not allow ldm [r12, #24], {r0-r5}.
	; To save 6 cycles we could rewrite the ldm in terms of ldrs.
	
	; Retrieve second half of pt and second half of rand_0 from memory.
	ldr r12, =pt
	add r12, #24 ; 6*4
	ldr r13, =rand_0
	add r13, #24
	ldm r12, {r6-r11}
	ldm r13, {r0-r5}
	
	; xor second half of pt with second half of rand_0
	eor r6, r0
	eor r7, r1
	eor r8, r2
	eor r9, r3
	eor r10, r4
	eor r11, r5
	
	; Store second half of rand_0 to the second half of in_0.
	ldr r12, =in_0
	add r12, #24
	stm r12, {r0-r5}

	; Retrieve the second half of rand_1 from memory.
	ldr r12, =rand_1
	add r12, #24
	ldm r12, {r0-r5}
	
	; xor the second half of rand_1 with the second half of pt xor rand_0.
	eor r6, r0
	eor r7, r1
	eor r8, r2
	eor r9, r3
	eor r10, r4
	eor r11, r5
	
	; Store the second half of rand_1 to the second half of in_1.
	ldr r12, =in_1
	add r12, #24
	stm r12, {r0-r5}
	
	MEND

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
$label KeyAddition
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
$label KeyAdditionNoLateShift
	; Requires the rc to be in r14
	; This version is not combined with the late shift. We need this in the first round.
	; The order in which we xor doesnt matter, so we add the rc first, such that r14 is free again.
	eor r2, r2, r14
	eor r3, r3, r14
	eor r8, r8, r14
	eor r9, r9, r14
	AddKeyNoLateShift
	MEND
	
	MACRO
$label EarlyShift
	mov r1, r1, ror #31
	mov r2, r2, ror #29
	mov r3, r3, ror #26
	mov r4, r4, ror #22
	mov r5, r5, ror #17
	mov r6, r6, ror #11
	mov r7, r7, ror #4
	mov r8, r8, ror #28
	mov r9, r9, ror #19
	mov r10, r10, ror #9
	mov r11, r11, ror #30
	MEND

	MACRO
$label LateShift
	mov r0, r0, ror #2
	mov r1, r1, ror #23
	mov r2, r2, ror #13
	mov r3, r3, ror #4
	mov r4, r4, ror #28
	mov r5, r5, ror #21
	mov r6, r6, ror #15
	mov r7, r7, ror #10
	mov r8, r8, ror #6
	mov r9, r9, ror #3
	mov r10, r10, ror #1
	;mov r11, r11, ror #0
	MEND

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

	MACRO
$label LateShift_Diffusion
	; First we compute r0 xor r1 xor ... xor r11 and store it in r12.
	; We will use this in computing a6-a11.
	mov r12, r0, ror #2
	eor r12, r1, ror #23
	eor r12, r2, ror #13
	eor r12, r3, ror #4
	eor r12, r4, ror #28
	eor r12, r5, ror #21
	eor r12, r6, ror #15
	eor r12, r7, ror #10
	eor r12, r8, ror #6
	eor r12, r9, ror #3
	eor r12, r10, ror #1
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
	mov r14, r0, ror #2
	
	; Registers: r0: a0; r12: -; r14: a0
	; Compute a0' = a0 xor a2 xor a6 xor a7 xor a9 xor a10 xor a11.
	; We store a9 xor a11 in r12 such that save one cycle when computing a3'.
	eor r12, r11, r9, ror #3

	eor r0, r12, r0, ror #2
	eor r0, r2, ror #13
	eor r0, r6, ror #15
	eor r0, r7, ror #10
	eor r0, r10, ror #1
	

	; Finished computing a0'.

	; As it turns out, we can't use r13 in eor operations.
	; Therefore we need another register.
	; We free r0 by storing a0' to SRAM.
	ldr r13, =saved_word
	str r0, [r13]

	; Store a0 in r0
	mov r0, r14

	; Store a0 xor a1 in r14
	eor r14, r0, r1, ror #23

	; Registers: r0: a0; r12: a9 xor a11; r14: a0 xor a1	
	; Compute a1' = a0 xor a1 xor a3 xor a7 xor a8 xor a10 xor a11.
	eor r1, r0, r1, ror #23
	eor r1, r3, ror #4
	eor r1, r7, ror #10
	eor r1, r8, ror #6
	eor r1, r10, ror #1
	eor r1, r11
	; Finished computing a1'.
	
	; Store a0 xor a1 xor a2 in r14
	eor r14, r2, ror #13
		
	; Registers: r0: a0; r12: a9 xor a11; r14: a0 xor a1 xor a2
	; Compute a2' = a0 xor a1 xor a2 xor a4 xor a8 xor a9 xor a11.
	eor r2, r14, r12
	eor r2, r4, ror #28
	eor r2, r8, ror #6
	; Finished computing a2'.
	
	; Store a3 xor a11 in r12
	eor r12, r11, r3, ror #4
	
	; Registers: r0: a0; r12: a3 xor a11; r14: a0 xor a1 xor a2
	; Compute a3' = a0 xor a1 xor a2 xor a3 xor a5 xor a9 xor a10.
	eor r3, r14, r3, ror #4
	eor r3, r5, ror #21
	eor r3, r9, ror #3
	eor r3, r10, ror #1
	; Finished computing a3'.
	
	; Store a0 xor a1 xor a2 xor a3 xor a4 xor a11 in r14
	eor r14, r12
	eor r14, r4, ror #28
	
	; Registers: r0: a0; r12: a3 xor a11; r14: a0 xor a1 xor a2 xor a3 xor a4 xor a11	
	; Compute a4' = a1 xor a2 xor a3 xor a4 xor a6 xor a10 xor a11.
	eor r4, r14, r0
	eor r4, r6, ror #15
	eor r4, r10, ror #1
	; Finished computing a4'.
	
	; Registers: r0: a0; r12: a3 xor a11; r14: a0 xor a1 xor a2 xor a3 xor a4 xor a11
	; Compute a5' = a0 xor a2 xor a3 xor a4 xor a5 xor a7 xor a11.
	eor r5, r14, r5, ror #21
	eor r5, r7, ror #10
	; We now have r5 = a5' xor a1
	; We need to retrieve a1 soon anyway to compute ???, so it's not too bad. 
	
	; I found that the following relation holds:
	; ai+6' = ai+6 xor ai xor ai' xor (a0 xor ... xor a11)
	; We make use of that to compute a6' to a11'.
	
	; We still have a0 in r0, which we need to compute a10'.
	; Store a10 in r14 because we need a10 to compute a8'.
	mov r14, r10, ror #1
	eor r6, r0, r6, ror #15
	
	; Retrieve a0' from SRAM.
	ldr r13, =saved_word
	ldr r0, [r13]
	; Finished computing a0'
	
	; Get the xor of everything back in r12.
	ldr r13, =xor_and_state	
	ldr r12, [r13, #24]
	
	; We xor a6-a11 right away such r12 is free and we can pipeline two ldr instructions.
	eor r6, r12
	eor r7, r12, r7, ror #10
	eor r8, r12, r8, ror #6
	eor r9, r12, r9, ror #3
	eor r10, r12, r10, ror #1
	eor r11, r12
	
	; a6' = a6 xor a0' xor a0 xor ALL
	; Currently in r6 is: a6 xor a0 xor ALL
	eor r6, r0
	; Finished computing a6'.
	
	; Load a1 into r12 and a2 into r14
	ldr r12, [r13, #4]
	ldr r14, [r13, #8]
	
	; Now that we have a1 in r12, we can finish computing a5'.
	eor r5, r12, ror #23
	; Finished computing a5'.
	
	; a7' = a7 xor a1' xor a1 xor ALL
	; Currently in r7 is: a7 xor ALL
	eor r7, r1
	eor r7, r12, ror #23
	; Finished computing a7'.
	
	; a8' = a8 xor a2' xor a2 xor ALL
	; Currently in r8 is: a8 xor ALL
	eor r8, r2
	eor r8, r14, ror #13
	; Finished computing a8'.
	
	; Load a3 into r12 and a4 into r14
	ldr r12, [r13, #12]
	ldr r14, [r13, #16]
	
	; a9' = a9 xor a3' xor a3 xor ALL
	; Currently in r9 is: a9 xor ALL
	eor r9, r3
	eor r9, r12, ror #4
	; Finished computing a9'.
	
	; a10' = a10 xor a4' xor a4 xor ALL
	; Currently in r10 is: a10 xor ALL
	eor r10, r4
	eor r10, r14, ror #28
	; Finished computing a10'.
	
	; Load a5 into r12 
	ldr r12, [r13, #20]
	
	; a11' = a11 xor a5' xor a5 xor ALL
	; Currently in r11 is: a11 xor ALL
	eor r11, r5
	eor r11, r12, ror #21
	; Finished computing a11'.
	MEND
	
	MACRO
$label SBoxF
	; Computes y_0, x_1, x_2 from x_0, x_1, x_2
	; Copy a_0 to r9
	mov r9, r0
	
	; Compute A_0 = F_A(a, c) = b_0 + a_1b_2 + b_1a_2 + b_1b_2 + b_2
	and r10, r3, r7
	eor r0, r1, r10
	and r10, r4, r6
	eor r0, r10
	and r10, r4, r7
	eor r0, r10
	eor r0, r7

	eor r10, r10 ; Clear r10
	
	; Compute B_0 = F_B(b, c) = c_0 + b_1c_2 + c_1b_2 + c_1c_2 + c_2 + 1
	and r10, r4, r8
	eor r1, r2, r10
	and r10, r5, r7
	eor r1, r10
	and r10, r5, r8
	eor r1, r10
	eor r1, r8
	mvn r1, r1
	
	eor r10, r10 ; Clear r10
	
	; Compute C_0 = F_C(a, c) = a_0 + c_1a_2 + a_1c_2 + a_1a_2 + a_2
	and r10, r5, r6
	eor r2, r9, r10
	and r10, r3, r8
	eor r2, r10
	and r10, r3, r6
	eor r2, r10
	eor r2, r6
	
	eor r10, r10 ; Clear r10
	eor r9, r9 ; Clear r9
	MEND
	
	MACRO
$label SBoxG
	; Computes y_0, y_1, x_2 from y_0, x_1, x_2
	
	; Copy a_1 to r9
	mov r9, r3
	
	; Compute A_1 = G_A(a, b) = A_0b_2 + B_0a_2 + B_0b_2 + B_0 + b_1 + b_2
	and r3, r0, r7
	and r10, r1, r6
	eor r3, r10
	and r10, r1, r7
	eor r3, r10
	eor r3, r1
	eor r3, r4
	eor r3, r7
	
	eor r10, r10 ; Clear r10
	
	; Compute B_1 = G_B(b, c) = B_0c_2 + C_0b_2 + C_0c_2 + C_0 + c_1 + c_2
	and r4, r1, r8
	and r10, r2, r7
	eor r4, r10
	and r10, r2, r8
	eor r4, r10
	eor r4, r2
	eor r4, r5
	eor r4, r8
	
	eor r10, r10 ; Clear r10
	
	; Compute C_1 = G_C(a, c) = A_0a_2 + A_0c_2 + C_0a_2 + A_0 + a_1 + a_2
	and r5, r0, r6
	and r10, r0, r8
	eor r5, r10
	and r10, r2, r6
	eor r5, r10
	eor r5, r0
	eor r5, r9
	eor r5, r6
	
	eor r10, r10 ; Clear r10
	eor r9, r9 ; Clear r9
	
	MEND
	
	MACRO
$label SBoxH
	; Computes y_0, y_1, y_2 from y_0, y_1, x_2
	
	; Copy a_2 to r9
	mov r9, r6
	
	; Compute A_2 = H_A(a, b) = b_2 + A_0B_1 + B_0A_1 + B_0B_1 + B_0
	and r6, r0, r4
	and r10, r1, r3
	eor r6, r10
	and r10, r1, r4
	eor r6, r10
	eor r6, r7
	eor r6, r1
	
	eor r10, r10 ; Clear r10
	
	; Compute B_2 = H_B(b, c) = c_2 + B_0C_1 + C_0B_1 + C_0C_1 + C_0 + 1
	and r7, r1, r5
	and r10, r2, r4
	eor r7, r10
	and r10, r2, r5
	eor r7, r10
	eor r7, r8
	eor r7, r2
	mvn r7, r7
	
	eor r10, r10 ; Clear r10
	
	; Compute C_2 = H_C(a, c) = a_2 + A_0A_1 + A_0C_1 + C_0A_1 + A_0
	and r8, r0, r3
	and r10, r0, r5
	eor r8, r10
	and r10, r2, r3
	eor r8, r10
	eor r8, r9
	eor r8, r0
	
	eor r10, r10 ; Clear r10
	eor r9, r9 ; Clear r9
	MEND
	
	MACRO
$label SBoxSlice $offset0, $offset1, $offset2
	;Retrieve the slice from memory
	ldr r12, =in_0
	ldr r13, =in_1
	ldr r14, =in_2
	
	ldr r0, [r12, $offset0]
	ldr r3, [r12, $offset1]
	ldr r6, [r12, $offset2]
	
	ldr r1, [r13, $offset0]
	ldr r4, [r13, $offset1]
	ldr r7, [r13, $offset2]

	ldr r2, [r14, $offset0]
	ldr r5, [r14, $offset1]
	ldr r8, [r14, $offset2]

	; PRE:  x_0 in r0-r2; x_1 in r3-r5; x_2 in r6-r8.
	SBoxF
	SBoxG
	SBoxH
	; POST: y_0 in r0-r2; y_1 in r3-r5; y_2 in r6-r8.
	
	; Save the slice to memory
	str r0, [r12, $offset0]
	str r3, [r12, $offset1]
	str r6, [r12, $offset2]
	
	str r1, [r13, $offset0]
	str r4, [r13, $offset1]
	str r7, [r13, $offset2]

	str r2, [r14, $offset0]
	str r5, [r14, $offset1]
	str r8, [r14, $offset2]
	MEND
	
	MACRO
$label CombineShares
	ldr r12, =in_0
	ldr r13, =in_1
	ldr r14, =in_2
	
	ldm r12, {r0-r5}
	ldm r13, {r6-r11}
	eor r0, r6
	eor r1, r7
	eor r2, r8
	eor r3, r9
	eor r4, r10
	eor r5, r11
	
	ldm r14, {r6-r11}
	eor r0, r6
	eor r1, r7
	eor r2, r8
	eor r3, r9
	eor r4, r10
	eor r5, r11
	
	; Store r0-r5 in memory because we need those registers to compute r6-r11.
	stm r12, {r0-r5}
	
	add r12, #24
	add r13, #24
	add r14, #24
	
	ldm r12, {r6-r11}
	ldm r13, {r0-r5}
	eor r6, r0
	eor r7, r1
	eor r8, r2
	eor r9, r3
	eor r10, r4
	eor r11, r5
	
	ldm r14, {r0-r5} 
	eor r6, r0
	eor r7, r1
	eor r8, r2
	eor r9, r3
	eor r10, r4
	eor r11, r5
	
	ldr r12, =in_0
	ldm r12, {r0-r5}

	MEND
	
	MACRO
$label Swap $arg0, $arg1
	eor $arg0, $arg0, $arg1
	eor $arg1, $arg0, $arg1
	eor $arg0, $arg0, $arg1
	MEND
	
; Probably can be made redundant by doing only imaginary swaps
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

rand_0 dcd 0x0b70434f, 0xa5f6d4ec, 0x43162069, 0x61681ac7, 0xe178aecc, 0x5e0ca734, 0x31d0db52, 0x940cdb11, 0xfc9b179e, 0x2327e178, 0xc0f7f07a, 0x68e52a24
rand_1 dcd 0xe7e5dec7, 0xf39854a9, 0x73b78d6f, 0x945d6c47, 0x04d9b9bc, 0xd3ca86c7, 0xb484a3b5, 0xd0ddec30, 0xca4a628e, 0xcb9e4db3, 0x9d19133f, 0xf19bf3c1
	
	AREA globalvars, DATA, READWRITE
round_nr dcd 0
xor_and_state dcd 0, 0, 0, 0, 0, 0, 0
saved_word dcd 0
ret_addr dcd 0
	
in_0 dcd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
in_1 dcd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
in_2 dcd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

	AREA code, CODE
	ENTRY
	EXPORT __main
	
__main
	; The offset is too large, so we can't jump in one go.
	b waypoint
	
sbox
	; Does S-Box on ALL shares
	; Store return address to memory
	ldr r13, =ret_addr
	str r14, [r13]
	
	;Do SBox
	SBoxSlice #0, #16, #32
	SBoxSlice #4, #20, #36
	SBoxSlice #8, #24, #40
	SBoxSlice #12, #28, #44
	
	; Return to saved return address
	ldr r13, =ret_addr
	ldr r15, [r13]

early_shift
; PRE: in_2 is in r0-r11
; Does early shift on ALL shares
; POST: in_1 is in r0-r11

	; Store return address to memory
	ldr r13, =ret_addr
	str r14, [r13]
	
	EarlyShift
	
	; Return to saved return address
	ldr r13, =ret_addr
	ldr r15, [r13]

waypoint
	b init

lateshift_diffusion
; PRE: in_1 is in r0-r11.
; Does diffusion on ALL shares
; POST: in_2 is in r0-r11.

	; Store return address to memory
	ldr r13, =ret_addr
	str r14, [r13]
	
	LateShift_Diffusion
	
	; Return to saved return address
	ldr r13, =ret_addr
	ldr r15, [r13]


diffusion
; PRE: in_1 is in r0-r11.
; Does diffusion on ALL shares
; POST: in_2 is in r0-r11.

	; Store return address to memory
	ldr r13, =ret_addr
	str r14, [r13]
	
	Diffusion
	
	; Return to saved return address
	ldr r13, =ret_addr
	ldr r15, [r13]

late_shift
; Does late shift on ALL shares
	
	; Store return address to memory
	ldr r13, =ret_addr
	str r14, [r13]
	
	; Do late shift
	; Load in_2.
	ldr r12, =in_0
	ldr r13, =in_2
	ldm r13, {r0-r11}
	
	; Late shift on in_2
	LateShift
	
	; Store in_2. Load in_0.
	stm r13, {r0-r11}
	ldm r12, {r0-r11}
	
	; Late shift on in_0
	LateShift
	
	; Store in_0. Load in_1.
	ldr r13, =in_1
	stm r12, {r0-r11}
	ldm r13, {r0-r11}
	
	; Early shift on in_1
	LateShift
	
	ldr r13, =in_1
	stm r13, {r0-r11}
	
	; Return to saved return address
	ldr r13, =ret_addr
	ldr r15, [r13]

init
	CreateShares	

first_round
	; We need to add the key + rc to one of the shares.
	; We already have the second half of in_2 in r6-r11,
	; so we will add it to in_2.
	
	; Retrieve first half of in_2
	ldr r12, =in_2
	ldm r12, {r0-r5}
	
	; Store rc for first round in r14
	mov r14, #11
	KeyAdditionNoLateShift
	
	bl diffusion
	bl early_shift
	
	ldr r12, =in_2
	ldr r13, =in_1
	stm r12, {r0-r11}
	ldm r13, {r0-r11}
	
	bl diffusion
	bl early_shift
	
	ldr r12, =in_1
	ldr r13, =in_0
	stm r12, {r0-r11}
	ldm r13, {r0-r11}
	
	bl diffusion
	bl early_shift
	
	ldr r12, =in_0
	stm r12, {r0-r11}
	
	bl sbox
	
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
	
	ldr r12, =in_0
	ldm r12, {r0-r11}
	
	KeyAddition
	bl diffusion
	bl early_shift
	
	ldr r12, =in_0
	ldr r13, =in_1
	stm r12, {r0-r11}
	ldm r13, {r0-r11}
	
	bl lateshift_diffusion
	bl early_shift
	
	ldr r12, =in_1
	ldr r13, =in_2
	stm r12, {r0-r11}
	ldm r13, {r0-r11}
	
	bl lateshift_diffusion
	bl early_shift
	
	ldr r12, =in_2
	stm r12, {r0-r11}
	
	bl sbox
	
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
	
	ldr r12, =in_0
	ldm r12, {r0-r11}
	
	KeyAddition
	bl diffusion
	
	ldr r12, =in_0
	ldr r13, =in_1
	stm r12, {r0-r11}
	ldm r13, {r0-r11}
	
	bl lateshift_diffusion
	
	ldr r12, =in_1
	ldr r13, =in_2
	stm r12, {r0-r11}
	ldm r13, {r0-r11}
	
	bl lateshift_diffusion
	
	ldr r12, =in_2
	stm r12, {r0-r11}
	
	CombineShares
	ReverseState

end
	nop
	b end
		
	END
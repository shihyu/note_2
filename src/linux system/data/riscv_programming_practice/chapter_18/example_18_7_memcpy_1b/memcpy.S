.text
.balign 4


/*
   void *memcpy(void* dest, const void* src, size_t n)
   a0=dest, a1=src, a2=n
*/
.global my_memcpy
my_memcpy:
	mv a3, a0 # Copy destination
loop:
	vsetvli t0, a2, e8, m1        # Vectors of 8b
	vle8.v v0, (a1)               # Load bytes
	add a1, a1, t0              # Bump pointer
	sub a2, a2, t0              # Decrement count
	vse8.v v0, (a3)               # Store bytes
	add a3, a3, t0              # Bump pointer
	bnez a2, loop               # Any more?

	ret                         # Return

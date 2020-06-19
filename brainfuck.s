# Brainfuck interpreter in X86 Assembly with various optimizations.
# Takes input from the terminal.
# Author: Anton Totomanov

.bss
arr: .skip 30000

.text
format_str: .asciz "We should be executing the following code:\n%s"

.global brainfuck

brainfuck:
  pushq %rbp
  movq %rsp, %rbp
  
  movq %rdi, %rsi
  movq %rsi, %r12
  movq $format_str, %rdi
  xor %rax, %rax
  call printf                # print the info string

  movq %r12, %rsi            # %rsi = address of next character
  xor %r12, %r12             # %r12 = pointer
# CONSTANT REGISTERS # (reg, reg) addresing is slower than (imm, reg)
  movq $8, %r14              # %r14 = 8
  movq $1, %rdx              # %r13 = 1
  xor %r10, %r10             # %r10 = 0

decode_char:
  lodsb                      # load next char in %al, increments %rsi

  cmpb $'>', %al             # > increment pointer
  je pointer_inc_begin

  cmpb $'<', %al             # < decrement pointer
  je pointer_dec_begin
 
  cmpb $'+', %al             # + increment byte @ pointer
  je byte_inc_begin
  
  cmpb $'-', %al             # - decrement byte @ pointer
  je byte_dec
  
  cmpb $'.', %al             # . output byte @ pointer
  je byte_out
  
  cmpb $',', %al             # , accept byte of input and store it @ pointer
  je byte_in
  
  cmpb $'[', %al             # [ if byte @ pointer = 0, jump IP after `]`
  je bropen_begin
  
  cmpb $']', %al             # ] if byte @ pointer!= 0, jump IP after `[`
  je bracket_closed

  cmpb %r10b, %al            # 0 = string end, exit 
  je end
  
  jmp decode_char

end:
  movq %rbp, %rsp
  popq %rbp
  ret

pointer_inc_begin:           # optimization: counts consecutive ">" and 
                             # increases the pointer in one operation
  xor %r15, %r15             # %r15 = counter
pointer_inc:
  incq %r15                  
pointer_inc_loop:
  lodsb
  cmpb $'>', %al
  je pointer_inc             # if nextchar is ">", increment counter
  addq %r15, %r12            # else, this is the end of the > run, so add the run length to the pointer
  decq %rsi                  # go back to the previous character
  jmp decode_char  

pointer_dec_begin:           # optimization: counts consecutive "<" and 
                             # decreases the pointer in one operation
  xor %r15, %r15 
pointer_dec:
  incq %r15                
pointer_dec_loop:
  lodsb
  cmpb $'<', %al
  je pointer_dec             # if nextchar is "<", increment counter
  subq %r15, %r12            # else, subtract the run length from the pointer
  decq %rsi                  # go back to previous char
  jmp decode_char

byte_inc_begin:              # same optimization
  xor %r15, %r15
byte_inc:
  incq %r15
byte_inc_loop:
  lodsb
  cmpb $'+', %al
  je byte_inc
  addq %r15, arr(%r12)       # add the number of consecutive "+"  to the arr[%r12]
  decq %rsi
  jmp decode_char

byte_dec:                    # optimizing this somehow makes my code run slower
  decb arr(%r12)
  jmp decode_char

byte_out:                    # print byte at arr[%r12]
  movq %rsi, %r9             # save the value of %rsi (current char)

  movq %rdx, %rax            # sys_write
  movq %rdx, %rdi            # stdout
  leaq arr(%r12), %rsi       # buffer = arr[%r12]
  syscall                    # %rdx = buffer length = 1 byte
  
  movq %r9, %rsi             # recover the value of %rsi (current char)

  jmp decode_char

byte_in:                     # get byte of input and store @ pointer
  movq %rsi, %r9             # save the value of %rsi in %r9

  movq %r10, %rax            # sys_read
  movq %r10, %rdi            # stdin
  leaq arr(%r12), %rsi       # store read byte in arr
  syscall                    # %rdx = buffer length = 1 byte

  movq %r9, %rsi             # recover the value of %rsi (current char)
  
  jmp decode_char

bropen_begin:                
  cmpb %r10b, arr(%r12)      # if the arr[%r12] = 0, jump after matching closing bracket
  movw %dx, %r8w             # %r8w = depth (nestedness) = 1
  je skip_until_matching_bracket
  lodsb                      # optimization: if [-] or [+], this means clear cell
  cmpb $'+', %al             # if nextchar is -/+
  cmpb $'-', %al
  jne bracket_open
  lodsb
  cmpb $']', %al             # -> and nextchar is ]
  je clear_cell              # clear this cell
  decq %rsi                  # go back one char
bracket_open:
  decq %rsi                  # go back one char
  pushq %rsi                 # push address of this [
  jmp decode_char            # now process contents of the loop

bracket_closed: 
  cmpb %r10b, arr(%r12)      # if the counter is 0, terminate loop
  je loop_terminate              
  movq (%rsp), %rsi          # else go back to start of loop (after "[")
  jmp decode_char            # and continue executing

loop_terminate:
  addq %r14, %rsp            # move stack pointer = "forget" the "["
  jmp decode_char 

inc_depth:
  incw %r8w

skip_until_matching_bracket: # to skip the loop when it begins at 0.
# this subroutine loops through the contents and searches for the matching end bracket
# since there can be nested loops inside it, we need to utilize a depth variable,
# which essentially tells us if the "]" closes our main loop or some other nested loop
  lodsb
  cmpb $'[', %al             # if nested loop inside 0 loop, increase depth and continue
  je inc_depth
  cmpb $']', %al                 
  je dec_depth               # if next char is not ], continue this function
  jmp skip_until_matching_bracket       # if it is ], continue execution outside loop

dec_depth:                   # decreases depth and checks if it's 0
  decw %r8w
  cmp %r10w, %r8w            # if depth is 0, then it is the matching bracket of the 0 loop,
  je decode_char             # so continue execution outside that bracket
  jmp skip_until_matching_bracket # else, continue

clear_cell:
  movb %r10b, arr(%r12)
  jmp decode_char

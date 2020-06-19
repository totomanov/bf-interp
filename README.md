# bf-interp
Brainfuck interpreter in AT&amp;T syntax x86 Assembly. Optimization strategies were gleaned from [Mats Linander's blog post.](http://calmerthanyouare.org/2015/01/07/optimizing-brainfuck.html)
The program was created as a part of the Computer Organisation course at TU Delft.

# Running on Linux
1. Clone this repo in a new directory.
```
git clone https://github.com/totomanov/bf-interp.git
```
2. Assemble the program with GCC.
```
gcc -no-pie -o brainfuck brainfuck.s
```
3. Create a file with brainfuck code. Example `helloworld.b`:
``` .b
++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.
````
4. Execute the binary with the file as an argument.
```
./brainfuck helloworld.b
```

# Debugging
1. Pass the ```-g``` flag to GCC.
```
gcc -g -no-pie -o brainfuck brainfuck.s
```
2. Start the debugger.
```
gdb ./brainfuck
```

# Benchmarking
To benchmark the interpreter, you can run common benchamrking programs in brainfuck such as ```hanoi.b``` or ```mandelbrot.b```. 
They can be found at [this website](https://copy.sh/brainfuck/) which also shows the intended output.
 
### Measuring execution time
Measuring the execution time of the interpreter is easily done with the GNU time utility. Simply prepend the execution call with ```time```.
```
time ./brainfuck mandelbrot.b
```

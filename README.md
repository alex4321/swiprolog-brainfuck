This is a simple brainfuck interpreter written with SWI-Prolog.

You can run it this way:
```
swipl brainfuck.pl program.bf
```
Where `program.bf` - file with your brainfuck-code.

E.g. for 

```
++++++++++
[
    >+++++++>++++++++++>+++>+<<<<-
]
>++.>+.+++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>.
```
it should give
```
C:\Users\alex4321\Documents\swiprolog-brainfuck>"C:\Program Files\swipl\bin\swipl.exe" brainfuck.pl program.bf
Hello World!
```
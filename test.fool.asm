push 5
push 3
add
push -7
mult
push 0
beq label2
push 0
b label3
label2:
push 1
label3:
push 1
beq label0
push 0
b label1
label0:
push 8
label1:
print
halt
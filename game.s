
.section .data
	
	paddleSize: .long 32
	paddleOffset: .long 100
	paddleMovSpeed: .long 6
	lives: .long 53
	xdiff: .long 1
	ydiff: .long -1
	time: .long 0
	moveBallcondition: .long 0
	startGame: .long 0
	score: .long 0
	speed: .long 8

.section .bss
	ballStartPaddle: .skip 16
	ballStart: .skip 16
	startTime: .skip 16
	bestScore: .skip 16

.section .text
.global main

main:
	# Set the timer frequency to 1000Hz
	pushl $1
	call set_timer_frequency
	addl $4, %esp

	# Register the handle for the timer IRQ (IRQ0) and enable it.
	pushl $irq0
	pushl $0
	call set_irq_handler
	call enable_irq
	addl $8, %esp

	# Register the handle for the timer IRQ (IRQ0) and enable it.
	pushl $irq1
	pushl $1
	call set_irq_handler
	call enable_irq
	addl $8, %esp


	# Set up VGA stuff
	call color_text_mode
	call hide_cursor

	# Clear the screen
	movb $' ', %al
	movb $0x5E, %ah
	movl $25*80, %ecx
	movl $vga_memory, %edi
	cld
	rep stosw
	
	#start drawing the game and fill the variables
	movl $0, startGame
	movl $0, bestScore
	movl $0, moveBallcondition
	movl $vga_memory + 160*22 - 84, ballStart
	movl $vga_memory + 160*22 - 84, ballStartPaddle
	call drawBall
	call drawPaddles
	call drawLeftWall
	call drawRightWall
	call drawLowerWallStart
	call drawTopWall

#draw the commands and their meaning on the screen
drawCommands:
	movb $'r', vga_memory 
	movb $':', vga_memory + 2
	movb $'r', vga_memory + 4
	movb $'e', vga_memory + 6
	movb $'s', vga_memory + 8
	movb $'t', vga_memory + 10
	movb $'a', vga_memory + 12
	movb $'r', vga_memory + 14
	movb $'t', vga_memory + 16
	movb $' ', vga_memory + 18
	movb $'s', vga_memory + 20
	movb $'p', vga_memory + 22
	movb $'a', vga_memory + 24
	movb $'c', vga_memory + 26
	movb $'e', vga_memory + 28
	movb $':', vga_memory + 30
	movb $'h', vga_memory + 32
	movb $'i', vga_memory + 34
	movb $'t', vga_memory + 36
	movb $' ', vga_memory + 38
	
#when the game is restarted reflect that on it's state
restartGame:
	movl $0, startGame
#keeps on looping while the game is on to maintain the scree
#will check if the score is 0 than this loop will stop
gameLoop:
	
	movb $' ', vga_memory + 160*11+60
	movb $' ', vga_memory + 160*11+62
	movb $' ', vga_memory + 160*11+64
	movb $' ', vga_memory + 160*11+66
	movb $' ', vga_memory + 160*11+68
	movb $'l', vga_memory + 60
	movb $'i', vga_memory + 62
	movb $'v', vga_memory + 64
	movb $'e', vga_memory + 66
	movb $'s', vga_memory + 68
	movb $':', vga_memory + 70
	movb $' ', vga_memory + 80
	call drawBall
	movb lives, %dl
	movb %dl, vga_memory + 74
	cmpb $48, %dl
	je endGame
	cmpb $1, moveBallcondition
	je moveBall
	jmp gameLoop

#draws the score on the screen and decreases the speed by 1 everytime the score is updated
updateScore:
	push %ebp		#stack routine
	movl %esp, %ebp
	cmpl $3, speed		#decrease the speed if its still slow
	jg incSpeed
continueUpdating:
	movb $'s', vga_memory + 82	#draw the score word	
	movb $'c', vga_memory + 84
	movb $'o', vga_memory + 86
	movb $'r', vga_memory + 88
	movb $'e', vga_memory + 90
	movb $':', vga_memory + 92
	movb $' ', vga_memory + 94
	movb $' ', vga_memory + 96
	movb $' ', vga_memory + 98
	movb $' ', vga_memory + 100
	movb $' ', vga_memory + 102
	movb $' ', vga_memory + 104
	movl $vga_memory + 104, %esi
	movl score, %eax
	movl $10, %ebx
loopScore:
	movl $0, %edx			#loop to display each number in it's place
	div %ebx
	addl $48, %edx
	movb %dl, (%esi)
	subl $2, %esi
	cmpl $0, %eax
	jg loopScore
	movl %ebp, %esp
	pop %ebp
	ret
#this will increment the speed after it's checked that it's not below 3
incSpeed:
	subl $1, speed
	jmp continueUpdating

endGame:
	movl score, %eax		#if the lives are 0 this function is activated 
	movl $0, score			#it will loop until the user press r
	cmpl bestScore, %eax
	jg printBestScore

updateBestScore:
	movb $'b', vga_memory + 108	#uses the same technique as displaying the course
	movb $'e', vga_memory + 110
	movb $'s', vga_memory + 112
	movb $'t', vga_memory + 114
	movb $':', vga_memory + 116
	movl $vga_memory + 128, %esi
	movb bestScore, %al
	movl $10, %ebx
loopBestScore:
	movl $0, %edx
	div %ebx
	addl $48, %edx
	movb %dl, (%esi)
	subl $2, %esi
	test %eax, %eax
	jnz loopBestScore

	
endGameC:
	movb $' ', vga_memory + 94		#this loop is kept active until r is pressed
	movb $' ', vga_memory + 96
	movb $' ', vga_memory + 98
	movb $' ', vga_memory + 100
	movb $' ', vga_memory + 102
	movb $' ', vga_memory + 104
	movb $'L', vga_memory + 160*11+60
	movb $'o', vga_memory + 160*11+62
	movb $'s', vga_memory + 160*11+64
	movb $'e', vga_memory + 160*11+66
	movb $'r', vga_memory + 160*11+68
	movb startGame, %dl
	cmpb $1, %dl
	je restartGame
	jmp endGameC

printBestScore:
	movl %eax, bestScore			#if the new score is bigger than the old one, save it
	jmp updateBestScore


moveBall:
	cmpb $0, moveBallcondition		#function to move the ball
	je gameLoop				#check first if the ball is allowed to move
	pushl ballStart				
	pushl ballStart
	movl time, %edi
	addl speed, %edi
	movl %edi, startTime
retime:
	movl startTime, %edi			#delay the movement a bit 
	subl time, %edi
	cmpl $0, %edi
	jg retime
	call calcNextPixel			#calculate the next position and see if we need to avoid it
	movl ballStart, %edx
	movb (%edx), %cl
	cmpl $vga_memory + 160*2, %edx
	jle hitTop
	cmpb $'|', %cl
	jz hitSides
	cmpb $'=', %cl
	jz hitPaddle
	cmpb $'-', %cl
	jz decLives
continue:
	popl %eax				#clear the old ball position and draw the new one
	movb $' ', (%eax)
	call drawBall
	jmp moveBall

calcNextPixel:	
	cmpb $0, moveBallcondition		#function to move the ball
	je gameLoop				#check first if the ball is allowed to move			
	movl ydiff, %eax
	movl $160, %ebx
	mul %ebx
	addl %eax, ballStart
	movl xdiff, %eax
	movl $2, %ebx
	mul %ebx
	addl %eax, ballStart
	ret
hitTop:
	pushl %eax				#if the ball hits the top flip the y axis addition
	pushl %ebx
	movl $-1, %eax
	movl ydiff, %ebx
	mul %ebx
	movl %eax, ydiff
	popl %ebx
	popl %eax
	popl ballStart
	call calcNextPixel
	jmp continue

hitPaddle:					#if the ball hits the paddle flip the y axis addition
	pushl %eax
	pushl %ebx
	movl $-1, %eax
	movl ydiff, %ebx
	mul %ebx
	movl %eax, ydiff
	popl %ebx
	popl %eax
	popl ballStart
	addl $1, score
	call updateScore
	call calcNextPixel
	jmp continue

hitSides:
	pushl %eax				#if we hit the side flip the x axis addition
	pushl %ebx
	movl $-1, %eax
	movl xdiff, %ebx
	mul %ebx
	movl %eax, xdiff
	popl %ebx
	popl %eax
	popl ballStart
	call calcNextPixel
	jmp continue

decLives:
	subl $1, lives				#if we hit the lower end decrement lives and reset the ball
	movl ballStartPaddle, %eax
	movl %eax, ballStart
	pop %eax
	movb $' ', (%eax)
	movl $1, xdiff
	movl $-1, ydiff
	call drawBall	
	movl $0, moveBallcondition
	jmp gameLoop
	

drawTopWall:					#as the name suggests, draws the top wall
	movl $0, %ebx
	movl $vga_memory, %eax
	addl $160, %eax
drawTopWallStart:
	addl $2, %ebx
	addl $2, %eax
	movb $'_', (%eax)
	cmpl $156, %ebx
	jl drawTopWallStart
	ret

drawLowerWall:					#as the name suggests, draws the lower wall
	movl $1, %ebx
	movl $160, %eax
	addl $vga_memory, %eax
drawLowerWallStart:
	addl $2, %ebx
	addl $2, %eax
	movb $'-', (%eax)
	cmpl $190, %ebx
	jnz drawLowerWallStart
	ret

drawLeftWall:					#as the name suggests, draws the left wall
	movl $1, %ebx
drawLeftWallStart:
	movl $160, %eax
	mul %ebx
	addl $vga_memory, %eax
	movb $'|', (%eax)
	addl $1, %ebx
	cmpl $24, %ebx
	jnz drawLeftWallStart
	ret
	

drawRightWall:					#as the name suggests, draws the right wall
	movl $1, %ebx
drawRightWallStart:
	movl $160, %eax
	mul %ebx
	addl $158, %eax
	addl $vga_memory, %eax
	movb $'|', (%eax)
	addl $1, %ebx
	cmpl $24, %ebx
	jnz drawRightWallStart
	ret
drawBall:					#draws the ball
	movl ballStart, %ebx	#ball position
	movb $'O', (%ebx)
	ret
	
drawPaddles:
	movl $vga_memory + 160*22, %edi	#start of paddle position
	movl $vga_memory + 160*22, %esi	#end of paddle position
	addl paddleOffset, %edi	
	addl paddleOffset, %esi
	subl paddleSize, %esi
	movb $61, %dl
paddleLoop:
	movb %dl, (%edi)		#draw the whole paddle
	subl $2, %edi
	cmpl %esi, %edi
	jnz paddleLoop
	ret

#keyboard event handler
irq1:
	inb $0x60, %al			#event handler for keyboard press
	cmpb $75, %al			#when left is pressed
	je detectedLeft
	cmpb $77, %al			#when right is pressed
	je detectedRight
	cmpb $57, %al			#when space is pressed
	je enableMove
	cmpb $19, %al			#when r is pressed
	je restart
	jmp end_of_irq1

restart:
	movl $0, moveBallcondition	#stop the ball from moving
	movl $1, xdiff			#reset the movement variables
	movl $-1, ydiff	
	movl $0, score			#reset the score
	call updateScore		#draw the reseted score
	movl $8, speed
	movl $53, lives			#reset lives to 5 lives
	movb $1, startGame		#allow the game to start again
	movl ballStart, %ebx		#clean the old position of the ball
	movb $' ', (%ebx)
	movl ballStartPaddle, %edx	#draw the ball over the paddle
	movl %edx, ballStart
	jmp end_of_irq1	
	
enableMove:
	movb $1, moveBallcondition	#enable the movement of the ball
	jmp end_of_irq1	

detectedRight:				#start the calculations to see if we can move right
	movl $vga_memory + 160*22 + 190, %ebx
	movl $vga_memory + 160*22, %ecx
	addl paddleOffset, %ecx
	addl paddleSize, %ecx
	addl paddleMovSpeed, %ecx
	cmpl %ecx, %ebx
	jge moveRight
	jmp end_of_irq1

moveRight:				#move the paddle to the right
	movl paddleMovSpeed, %ecx
	addl %ecx, paddleOffset
	call clearLine
	call drawPaddles
	jmp end_of_irq1

detectedLeft:				#start the calculations to see if we can move left
	movl $vga_memory + 160*22 + 32, %ebx
	movl $vga_memory + 160*22, %ecx
	addl paddleOffset, %ecx
	subl paddleMovSpeed, %ecx
	cmpl %ecx, %ebx
	jl moveLeft
	jmp end_of_irq1
moveLeft:				#move the paddle to the left
	movl paddleMovSpeed, %ecx
	subl %ecx, paddleOffset
	call clearLine
	call drawPaddles
	jmp end_of_irq1

clearLine:				#clean the line of the paddles
	movl $vga_memory + 160*22, %ecx
	movl %ecx, %ebx
	addl $156, %ebx
clearloop:
	addl $2, %ecx
	movb $' ', (%ecx)
	cmpl %ebx, %ecx
	jl clearloop
	ret



# Timer IRQ handler
irq0:
	# increment the time and go on.
	incl time
	jmp end_of_irq0





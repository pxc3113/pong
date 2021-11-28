STACK SEGMENT PARA STACK
    DB 64 DUP(' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
    WINDOW_WIDTH DW 140h;static
    WINDOW_HEIGHT DW 0c8h;static
    WINDOW_BOUNDS DW 6;static

    PREV_TIME_STAMP DB 0; DL is one byte that's why DB is used; variable used whenever time stamp changes

    BALL_ORIGINAL_X DW 0A0h
    BALL_ORIGINAL_Y DW 64h
    BALL_X DW 0A0h
    BALL_Y DW 0Ah
    BALL_SIZE DW 04h
    BALL_VELOCITY_X DW 05h
    BALL_VELOCITY_Y DW 02h
    
    PADDLE_LEFT_X DW 0Ah
    PADDLE_LEFT_Y DW 0Ah

    PADDLE_RIGHT_X DW 130h
    PADDLE_RIGHT_Y DW 0Ah

    PADDLE_WIDTH DW 05h
    PADDLE_HEIGHT DW 3Bh
    PADDLE_VELOCITY DW 05h
DATA ENDS

CODE SEGMENT PARA 'CODE'

    MAIN PROC FAR 
    ASSUME CS:CODE,DS:DATA,SS:STACK
    MOV AX,DATA
    MOV DS,AX
        
        CHECK_TIME:;only draw the ball when current time switches to the next interval

            ;first we need to get system time 
            MOV AH,2Ch;get system time command
            INT 21h; execute command; then the following registers store current time stamp by these units: DH=hr,CL=min,DH=sec,DL=10msec

            ;we want to draw the ball every 10 msec, so we compare previous time with DL register
            CMP DL, PREV_TIME_STAMP
            JE CHECK_TIME;if prev time = current time, then we simply update current time
            ;else if current time changes, we want to update PREV_TIME_STAMP and draw our ball
            MOV PREV_TIME_STAMP, DL
                        
            CALL CLEAR_SCREEN

            CALL MOVE_BALL
            CALL DRAW_BALL 

            CALL MOVE_PADDLES
            CALL DRAW_PADDLES 

            ;after drawing the ball, we want to repeat the process: check the time again and draw the next ball 
            JMP CHECK_TIME
        RET
    MAIN ENDP

    MOVE_BALL PROC NEAR
        
        ;update ball_x 
        MOV AX,BALL_VELOCITY_X
        ADD BALL_X,AX

        ;check if x is out of the left wall
        CMP BALL_X,00h
        ;if so(x<0) then reset ball to the origianl position
        ; JL RESET_BALL_POSITION
        JL NEGATE_VELOCITY_X

        ;check if x is out of the right wall
        MOV AX,WINDOW_WIDTH
        SUB AX,BALL_SIZE
        ; SUB AX,WINDOW_BOUNDS ;this line is used to move boundries inwards
        CMP BALL_X,AX
        ;if so then reset ball to the original position
        ; JG RESET_BALL_POSITION
        JG NEGATE_VELOCITY_X
        
        ;update ball_y 
        MOV AX,BALL_VELOCITY_Y
        ADD BALL_Y,AX

        ;check if y is out of the upper wall
        CMP BALL_Y,00h
        ;if so(x<0) negate y's velocity
        JL NEGATE_VELOCITY_Y

        ;check if y is out of the bottom wall
        MOV AX,WINDOW_HEIGHT;-BALL_SIZE
        SUB AX,BALL_SIZE
        ; SUB AX,WINDOW_BOUNDS;this line is used to move boundries inwards
        CMP BALL_Y,AX
        ;if so then negate y's velocity
        JG NEGATE_VELOCITY_Y

        RET

        RESET_POSITION:
            CALL RESET_BALL_POSITION
            RET
            
        NEGATE_VELOCITY_X:
            NEG BALL_VELOCITY_X
            RET

        NEGATE_VELOCITY_Y:
            NEG BALL_VELOCITY_Y
            RET
        
    MOVE_BALL ENDP

MOVE_PADDLES PROC NEAR               ;process movement of the paddles
		
;       Left paddle movement
		
		;check if any key is being pressed (if not check the other paddle)
		MOV AH,01h
		INT 16h
		JZ CHECK_RIGHT_PADDLE_MOVEMENT ;ZF = 1, JZ -> Jump If Zero
		
		;check which key is being pressed (AL = ASCII character)
		MOV AH,00h
		INT 16h
		
		;if it is 'w' or 'W' move up
		CMP AL,77h ;'w'
		JE MOVE_LEFT_PADDLE_UP
		CMP AL,57h ;'W'
		JE MOVE_LEFT_PADDLE_UP
		
		;if it is 's' or 'S' move down
		CMP AL,73h ;'s'
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL,53h ;'S'
		JE MOVE_LEFT_PADDLE_DOWN
		JMP CHECK_RIGHT_PADDLE_MOVEMENT
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX
			; JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX
			; JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
	MOVE_PADDLES ENDP

    RESET_BALL_POSITION PROC NEAR
        MOV AX,BALL_ORIGINAL_X
        MOV BALL_X,AX

        MOV AX,BALL_ORIGINAL_Y
        MOV BALL_Y,AX

        RET
    RESET_BALL_POSITION ENDP

    DRAW_BALL PROC NEAR

        MOV CX,BALL_X;set the initial drawing column (X)
        MOV DX,BALL_Y;set the initial drawing row (Y)

        DRAW_BALL_:
        ; first draw the pixel
            MOV AH,0Ch;set the config to writing a pixel
            MOV AL,0Fh;choose white as color
            MOV BH,00h;set the page #
            INT 10h;execute the config

        ;then increment current column to draw the next pixel
            INC CX

        ;check if we're oob
            MOV AX,CX
            SUB AX,BALL_X
            CMP AX,BALL_SIZE
        ;if not oob, then draw the next pixel
            JNG DRAW_BALL_
        ;else if oob, then increment current row, DX, check if DX is oob, and reset current column CX
            INC DX
            MOV CX,BALL_X
            MOV AX,DX
            SUB AX,BALL_Y
            CMP AX,BALL_SIZE
            JNG DRAW_BALL_
        RET
    DRAW_BALL ENDP

    DRAW_PADDLES PROC NEAR
        MOV CX,PADDLE_LEFT_X;set the initial drawing column (X)
        MOV DX,PADDLE_LEFT_Y;set the initial drawing row (Y)
        DRAW_LEFT_PADDLE:

            MOV AH,0Ch;set the config to writing
            MOV AL,0Fh;choose white as color
            MOV BH,00h;set the page number
            INT 10h;execute the config

            INC CX
            MOV AX,CX
            SUB AX,PADDLE_LEFT_X
            CMP AX,PADDLE_WIDTH
            JNG DRAW_LEFT_PADDLE

            INC DX
            MOV CX,PADDLE_LEFT_X

            MOV AX,DX
            SUB AX,PADDLE_LEFT_Y
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_LEFT_PADDLE
        MOV CX,PADDLE_RIGHT_X;set the initial drawing column (X)
        MOV DX,PADDLE_RIGHT_Y;set the initial drawing row (Y)
        DRAW_RIGHT_PADDLE:
            
            MOV AH,0Ch;set the config to writing
            MOV AL,0Fh;choose white as color
            MOV BH,00h;set the page number
            INT 10h;execute the config

            INC CX
            MOV AX,CX
            SUB AX,PADDLE_RIGHT_X
            CMP AX,PADDLE_WIDTH
            JNG DRAW_RIGHT_PADDLE

            INC DX
            MOV CX,PADDLE_RIGHT_X

            MOV AX,DX
            SUB AX,PADDLE_RIGHT_Y
            CMP AX,PADDLE_HEIGHT
            JNG DRAW_RIGHT_PADDLE
        RET
    DRAW_PADDLES ENDP

    CLEAR_SCREEN PROC NEAR
        MOV AH,00h;set the config to video mode
        MOV AL,13h;choose the video mode
        INT 10h;execute the config
        
        MOV AH,0Bh;set the config
        MOV BH,00h;to the bckgrd color
        MOV BL,00h;choose black as bckgrd color
        INT 10h;execute the config
        RET
    CLEAR_SCREEN ENDP

CODE ENDS
END
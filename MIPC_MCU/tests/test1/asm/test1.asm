.include "IO_map_addr.asm"
#--------------------------------------------------------------
#							 Global constants
#--------------------------------------------------------------
.eqv STACK_INIT_ADDR 		0x800
.eqv CLRKEY1IFG 			0xFFF7
.eqv CLRKEY2IFG 			0xFFEF
.eqv CLRKEY3IFG 			0xFFDF
.eqv KEY3IE_KEY2IE_KEY1IE 	0x38
#--------------------------------------------------------------
#							 Data Segment
#--------------------------------------------------------------
.data 
IV: .word main            # Start of Interrupt Vector Table
	.word UartRX_ISR
	.word UartRX_ISR
	.word UartTX_ISR
	.word BT_ISR
	.word KEY1_ISR
	.word KEY2_ISR
	.word KEY3_ISR
	.word FIR_ISR

N:	.word 0xB71B00	
#--------------------------------------------------------------
#							 Code Segment
#--------------------------------------------------------------
.text
main:	
	addi $sp,$zero,STACK_INIT_ADDR 	# $sp=0x800 
	sw   $0,IE        				# IE=0
	sw   $0,IFG        				# IFG=0
	addi $t0,$zero,KEY3IE_KEY2IE_KEY1IE 
	sw   $t0,IE       				# KEY3IE=1, KEY2IE=1, KEY1IE=1, clear the rest bits 		
	ori  $k0,$k0,0x01    			# EINT, $k0[0]=1 ($k0[0] uses as GIE)
	
L:	j    L		    				# infinite loop
	
KEY1_ISR:	
	lw   $t0,PORT_SW       			# read the state of PORT_SW[7-0]
	sw   $t0,PORT_HEX0 				# write to PORT_HEX0[7-0]
	sw   $t0,PORT_HEX1 				# write to PORT_HEX1[7-0]
	sw   $t0,PORT_LEDR 				# write to PORT_LEDR[7-0]
	
	lw   $t1,IFG 					# read IFG
	andi $t1,$t1,CLRKEY1IFG 
	sw   $t1,IFG 					# clr KEY1IFG
	jr   $k1       					# reti
	
KEY2_ISR:	
	lw   $t0,PORT_SW       			# read the state of PORT_SW[7-0]
	sw   $t0,PORT_HEX2 				# write to PORT_HEX2[7-0]
	sw   $t0,PORT_HEX3 				# write to PORT_HEX3[7-0]
	sw   $t0,PORT_LEDR 				# write to PORT_LEDR[7-0]
			
	lw   $t1,IFG  					# read IFG
	andi $t1,$t1,CLRKEY2IFG 
	sw   $t1,IFG  					# clr KEY2IFG
	jr   $k1        				# reti

KEY3_ISR:	
	lw   $t0,PORT_SW       			# read the state of PORT_SW[7-0]
	sw   $t0,PORT_HEX4 				# write to PORT_HEX4[7-0]
	sw   $t0,PORT_HEX5 				# write to PORT_HEX5[7-0]
	sw   $t0,PORT_LEDR 				# write to PORT_LEDR[7-0]
			
	lw   $t1,IFG  					# read IFG
	andi $t1,$t1,CLRKEY3IFG 
	sw   $t1,IFG  					# clr KEY3IFG
	jr   $k1        				# reti
		
BT_ISR:		
	jr   $k1        				# reti 
		       
FIR_ISR:	
	jr   $k1        				# reti
		
UartRX_ISR:	
	jr   $k1        				# reti            

UartTX_ISR:	
	jr   $k1        				# reti    


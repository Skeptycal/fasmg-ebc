; ebctest.asm
; Taken from EBCDebugger's EbcTest/EbcTest.cod
; See http://www.uefi.org/node/550

include 'ebc.inc'
include 'efi.inc'
include 'format.inc'
include 'utf8.inc'

format peebc efi
entry EfiMain

section '.text' code executable readable

TestSubRoutine2:
  ;   STATIC UINT8  TestVariable3 = 9;
  ;   Arg5 = Arg1 + Arg2 + Arg3 + Arg4;
  MOVnw     R7, @R0(+0,+16)
  MOVnw     R4, @R0(+1,+16)
  ADD       R7, R4
  MOVnw     R4, @R0(+2,+16)
  ADD       R7, R4
  MOVnw     R4, @R0(+3,+16)
  ADD       R7, R4
  MOVnw     @R0(+4,+16), R7
  ;   TestVariable1 = 6;
  MOVreld   R7, TestVariable1
  MOVInw    @R7, (0,6)
  ;   TestVariable2 = Arg3 + TestVariable1 + TestVariable3;
  MOVnw     R4, @R0(+2,+16)
  MOVnw     R7, @R7
  ADD       R4, R7
  MOVreld   R7, TestVariable3
  MOVbw     R7, @R7
  ADD       R4, R7
  MOVreld   R7, TestVariable2
  MOVqw     @R7, R4
  ;   return EFI_SUCCESS;
  MOVqd     R7, R6
  RET

TestSubRoutine:
  MOVqw     R0, R0(+0,-80)
  ;   Arg3 = Arg1 + Arg2;
  MOVnw     R7, @R0(+0,+96)
  MOVnw     R4, @R0(+1,+96)
  ADD       R7, R4
  MOVnw     @R0(+2,+96), R7
  ;   Arg5 = Arg4 - Arg3;
  MOVnw     R7, @R0(+2,+96)
  NEG       R7, R7
  MOVnw     R4, @R0(+3,+96)
  ADD       R4, R7
  MOVnw     @R0(+4,+96), R4
  ;   Arg7 = Arg6 * Arg5;
  MOVnw     R7, @R0(+5,+96)
  MOVnw     R4, @R0(+4,+96)
  MUL       R7, R4
  MOVnw     @R0(+6,+96), R7
  ;   Arg9 = Arg7 / Arg8;
  MOVnw     R7, @R0(+6,+96)
  MOVnw     R4, @R0(+7,+96)
  DIVU      R7, R4
  MOVnw     @R0(+8,+96), R7
  ;   Arg10 = Arg7 % Arg6;
  MOVnw     R7, @R0(+6,+96)
  MOVnw     R4, @R0(+5,+96)
  MODU      R7, R4
  MOVnw     @R0(+9,+96), R7
  ;   Arg10 = Arg10 | Arg9;
  MOVnw     R7, @R0(+9,+96)
  MOVnw     R4, @R0(+8,+96)
  OR        R7, R4
  MOVnw     @R0(+9,+96), R7
  ;   Arg10 = Arg10 & Arg7;
  MOVnw     R7, @R0(+9,+96)
  MOVnw     R4, @R0(+6,+96)
  AND       R7, R4
  MOVnw     @R0(+9,+96), R7
  ;   if (Arg1 == 0) {
  MOVnw     R7, @R0(+0,+96)
  CMPeq     R7, R6
  JMP8cs    _B2_6 
  ;     return EFI_SUCCESS;
  ;   }
  ;   TestSubRoutine (0, 2, 3, 4, 5, 6, 7, 8, 9, 10);
  MOVnw     @R0, R6
  MOVInw    @R0(1,0), (0,2)
  MOVInw    @R0(2,0), (0,3)
  MOVInw    @R0(3,0), (0,4)
  MOVInw    @R0(4,0), (0,5)
  MOVInw    @R0(5,0), (0,6)
  MOVInw    @R0(6,0), (0,7)
  MOVInw    @R0(7,0), (0,8)
  MOVInw    @R0(8,0), (0,9)
  MOVInw    @R0(9,0), (0,10)
  CALL      TestSubRoutine
  ;   TestSubRoutine2 (Arg1, Arg2, Arg7, Arg9, Arg10);
  MOVnw     @R0, @R0(+0,+96)
  MOVnw     @R0(+1,+0), @R0(+1,+96)
  MOVnw     @R0(+2,+0), @R0(+6,+96)
  MOVnw     @R0(+3,+0), @R0(+8,+96)
  MOVnw     @R0(+4,+0), @R0(+9,+96)
  CALL      TestSubRoutine2
_B2_6:
  ;   return EFI_SUCCESS;
  MOVqd     R7, R6 
  MOVqw     R0, R0(+0,+80)
  RET

EfiMain:
  CALL      BSSInit
  MOVqw     R0, R0(+0,-112)
  ;   UINT16 test = 0x1234;
  MOVIww    @R0(+0,+88), +4660
  ;   EFI_STATUS  Status;
  ;   SystemTable->ConOut->OutputString (
  MOVnw     R7, @R0(+1,+128)
  MOVnw     R7, @R7(+5,+24)
  ;                          SystemTable->ConOut,
  MOVnw     R4, @R0(+1,+128)
  MOVnw     @R0, @R4(+5,+24)
  MOVreld   R4, __STRING$1
  MOVnw     @R0(+1,+0), R4
  CALLEX    @R7(+1,+0)
  ;                          L"Hello EBC Test!\r\n"
  ;                          );
  ;   TestVariable1 = 6;
  MOVreld   R7, TestVariable1
  MOVInw    @R7, (0,6)
  ;   TestSubRoutineSub (1, 5);
  MOVInw    @R0, (0,1)
  MOVInw    @R0(1,0), (0,5)
  CALL      TestSubRoutineSub
  ;   SystemTable->ConOut->OutputString (
  MOVnw     R7, @R0(+1,+128)
  MOVnw     R7, @R7(+5,+24)
  ;                          SystemTable->ConOut,
  MOVnw     R4, @R0(+1,+128)
  MOVnw     @R0, @R4(+5,+24)
  ;                          TestStr
  MOVreld   R4, TestStr
  MOVnw     @R0(+1,+0), @R4
  CALLEX    @R7(+1,+0)
  ;                          );
  ;   test = test & 0xFF;
  MOVww     @R0(+0,+88), @R0(+0,+88)

  ;   Status = TestSubRoutine (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
  MOVInw    @R0, (0,1)
  MOVInw    @R0(1,0), (0,2)
  MOVInw    @R0(2,0), (0,3)
  MOVInw    @R0(3,0), (0,4)
  MOVInw    @R0(4,0), (0,5)
  MOVInw    @R0(5,0), (0,6)
  MOVInw    @R0(6,0), (0,7)
  MOVInw    @R0(7,0), (0,8)
  MOVInw    @R0(8,0), (0,9)
  MOVInw    @R0(9,0), (0,10)
  CALL      TestSubRoutine
  MOVnw     @R0(+0,+96), R7
  MOVnw     @R0(+0,+80), @R0(+0,+96)
  ;   SystemTable->ConOut->OutputString (
  MOVnw     R7, @R0(+1,+128)
  MOVnw     R7, @R7(+5,+24)
  ;                          SystemTable->ConOut,
  MOVnw     R4, @R0(+1,+128)
  MOVnw     @R0, @R4(+5,+24)
  MOVreld   R4, __STRING$2
  MOVnw     @R0(+1,+0), R4
  CALLEX    @R7(+1,+0)
  ;                          L"Goodbye EBC Test!\r\n
  ;                          );"
  ;   return Status;
  MOVnw     R7, @R0(+0,+80)
  MOVqw     R0, R0(+0,+112)
  BREAK     3
  RET

TestSubRoutineSub:
  ;   Arg2 = Arg1 + Arg2;
  MOVnw     R7, @R0(+0,+16)
  MOVnw     R4, @R0(+1,+16)
  ADD       R7, R4
  MOVnw     @R0(+1,+16), R7
  ;   return EFI_SUCCESS;
  MOVqd     R7, R6
  RET

BSSInit:
  MOVreld   R4, TestStr
  MOVreld   R5, __STRING$0
  MOVnd     @R4, R5
  MOVreld   R4, TestVariable1
  MOVInw    @R4, (0,4)
  RET

section '.data' data readable writeable
__STRING$2: DU "Goodbye EBC Test!", 0x0D, 0x0A, 0x00
__STRING$1: DU "Hello EBC Test!", 0x0D, 0x0A, 0x00
__STRING$0: DU "789456123", 0x0D, 0x0A, 0x00
TestStr:    DD 2 DUP ?
TestVariable1: DD 2 DUP ?
TestVariable2: DD 0x00000003, 0x00000000
TestVariable3: DB 9

section '.reloc' fixups data discardable

;
; Driver - EBC Driver sample
; Copyright � 2016 Pete Batard <pete@akeo.ie>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;

include 'ebc.inc'
include 'efi.inc'
include 'format.inc'
include 'utf8.inc'

DriverVersion = 0x10

struct EFI_CUSTOM_PROTOCOL
  Hello                 VOID_PTR
ends

struct EFI_COMPONENT_NAME_PROTOCOL
  GetDriverName         VOID_PTR
  GetControllerName     VOID_PTR
  SupportedLanguages    VOID_PTR
ends

struct EFI_DRIVER_BINDING_PROTOCOL
  Supported             VOID_PTR
  Start                 VOID_PTR
  Stop                  VOID_PTR
  Version               UINT32
  ImageHandle           EFI_HANDLE
  DriverBindingHandle   EFI_HANDLE
ends

format peebc efiboot
entry DriverInstall

section '.text' code executable readable

Print:
  MOVREL    R1, gST
  MOV       R1, @R1
  MOVn      R1, @R1(EFI_SYSTEM_TABLE.ConOut)
  PUSHn     @R0(0,+16)
  PUSHn     R1
  CALLEX    @R1(SIMPLE_TEXT_OUTPUT_INTERFACE.OutputString)
  MOV       R0, R0(+2,0)
  RET

PrintHex32:
  XOR       R6, R6
  MOV       R3, R6
  NOT32     R4, R6
  MOVREL    R5, Digits
  MOVREL    R7, HexStr
  ADD       R7, R6(4)
  MOV       R1, @R0(0,+16)
  AND       R1, R4
  PUSH      R1
@1:
  MOV       R1, @R0
  EXTNDD    R2, R6(4)
  MUL       R2, R3(-7)
  NEG       R2, R2
  SHR       R1, R2
  ADD       R1, R1
  PUSH      R5
  ADD       R5, R1
  MOVw      @R7, @R5
  ADD       R7, R6(2)
  POP       R5
  SHR32     R4, R6(4)
  AND       @R0, R4
  ADD       R3, R6(1)
  CMPIgte   R3, 8
  JMPcc     @1b
  POP       R1
  MOVREL    R1, HexStr
  PUSH      R1
  CALL      Print
  POP       R1
  RET

CallFailed:
  PUSH      R7
  PUSH      R1
  CALL      Print
  POP       R1
  CALL      PrintHex32
  POP       R7
  RET

GetDriverName:
  MOV       R1, @R0(+2,+16)
  MOVREL    @R1, DrvName
  MOVI      R7, EFI_SUCCESS
  RET

BindingSupported:
  ; TODO: detect if the native arch is 32 or 64 bit and return the right status
  MOVI      R6, EFI_32BIT_ERROR
  MOVI      R7, EFI_UNSUPPORTED
  OR        R7, R6
  RET

Hello:
  MOVREL    R1, HelloMsg
  PUSH      R1
  CALL      Print
  POP       R1
  RET

DriverInstall:
  XOR       R6, R6
  MOVREL    R1, ImageHandle
  MOVn      @R1, @R0(EFI_MAIN_PARAMETERS.ImageHandle)
  MOVREL    R1, gST
  MOVn      @R1, @R0(EFI_MAIN_PARAMETERS.SystemTable)

  ; Check for an already running driver
  MOVREL    R1, CustomProtocolInterface
  PUSHn     R1
  PUSHn     R6
  MOVREL    R1, CustomProtocolGuid
  PUSHn     R1
  MOVREL    R1, gST
  MOV       R1, @R1
  MOV       R1, @R1(EFI_SYSTEM_TABLE.BootServices)
  CALLEX    @R1(EFI_BOOT_SERVICES.LocateProtocol)
  MOV       R0, R0(+3,+0)
  CMPI32eq  R7, EFI_SUCCESS
  JMPcc     @0f

  MOVREL    R1, AIMsg
  PUSHn     R1
  CALL      Print
  MOV       R0, R0(+1,+0)
  MOVI      R7, EFI_LOAD_ERROR
  RET

@0:
  ; The only valid status we expect is NOT FOUND here
  MOVIq     R1, EFI_NOT_FOUND
  CMP64eq   R1, R7
  JMPcs     @0f
  MOVId     R1, EFI_NOT_FOUND or EFI_32BIT_ERROR
  CMP32eq   R1, R7
  JMPcs     @0f

  MOVREL    R1, USMsg
  PUSHn     R1
  CALL      Print
  MOV       R0, R0(+1,+0)
  RET

@0:
  ; Fill in the Custom Protocol interface
  MOVREL    R1, CustomProtocolInterface
  MOVREL    R2, Hello
  MOV       R7, R1(EFI_CUSTOM_PROTOCOL.Hello)
  SUB       R2, R7(4)
  MOVn      @R7, R2
  BREAK     5 ; Generate a Thunk to allow native -> EBC call
  ; Fill in the Component Name interfaces
  MOVREL    R1, ComponentName
  MOVREL    R2, GetDriverName
  MOV       R7, R1(EFI_COMPONENT_NAME_PROTOCOL.GetDriverName)
  SUB       R2, R7(4)
  MOVn      @R7, R2
  BREAK     5
  MOVn      @R1(EFI_COMPONENT_NAME_PROTOCOL.GetControllerName), R6
  MOVREL    R3, Eng
  MOVn      @R1(EFI_COMPONENT_NAME_PROTOCOL.SupportedLanguages), R3
  MOVREL    R1, ComponentName2
  MOVn      @R1(EFI_COMPONENT_NAME_PROTOCOL.GetDriverName), @R7
  MOVn      @R1(EFI_COMPONENT_NAME_PROTOCOL.GetControllerName), R6
  MOVREL    R3, En
  MOVn      @R1(EFI_COMPONENT_NAME_PROTOCOL.SupportedLanguages), R3
  ; Fill in DriverBinding
  MOVREL    R1, DriverBinding
  MOVREL    R2, BindingSupported
  MOV       R7, R1(EFI_DRIVER_BINDING_PROTOCOL.Supported)
  SUB       R2, R7(4)
  MOVn      @R7, R2
  BREAK     5
  MOVn      @R1(EFI_DRIVER_BINDING_PROTOCOL.Start), R6
  MOVn      @R1(EFI_DRIVER_BINDING_PROTOCOL.Stop), R6
  MOVI      R2, DriverVersion
  MOVd      @R1(EFI_DRIVER_BINDING_PROTOCOL.Version), R2
  MOVREL    R2, ImageHandle
  MOVn      @R1(EFI_DRIVER_BINDING_PROTOCOL.ImageHandle), @R2
  MOVn      @R1(EFI_DRIVER_BINDING_PROTOCOL.DriverBindingHandle), @R2

  ; Install the interface
  PUSHn     R1
  PUSHn     R6 ; EFI_NATIVE_INTERFACE = 0
  MOVREL    R1, CustomProtocolGuid
  PUSHn     R1
  MOVREL    R1, CustomProtocolHandle
  PUSHn     R1
  MOVREL    R1, gST
  MOV       R1, @R1
  MOV       R1, @R1(EFI_SYSTEM_TABLE.BootServices)
  CALLEX    @R1(EFI_BOOT_SERVICES.InstallProtocolInterface)
  MOV       R0, R0(+4,+0)
  MOVREL    R1, IPIMsg
  CMPI32eq  R7, EFI_SUCCESS
  JMPcc     CallFailed
  
  ; Grab a handle to this image, so that we can add an unload to our driver
  MOVI      R1, EFI_OPEN_PROTOCOL_GET_PROTOCOL
  PUSHn     R1
  PUSHn     R6
  MOVREL    R2, ImageHandle
  PUSHn     @R2
  MOVREL    R1, LoadedImage
  PUSHn     R1
  MOVREL    R1, gEfiLoadedImageProtocolGuid
  PUSHn     R1
  PUSHn     @R2
  MOVREL    R1, gST
  MOV       R1, @R1
  MOV       R1, @R1(EFI_SYSTEM_TABLE.BootServices)
  CALLEX    @R1(EFI_BOOT_SERVICES.OpenProtocol)
  MOV       R0, R0(+6,+0)
  MOVREL    R1, OPMsg
  CMPI32eq  R7, EFI_SUCCESS
  JMPcc     CallFailed

  ; Install driver
  PUSHn     R6
  MOVREL    R2, ComponentName
  PUSHn     R2
  MOVREL    R1, gEfiComponentName2ProtocolGuid
  PUSHn     R1
  PUSHn     R2
  MOVREL    R1, gEfiComponentNameProtocolGuid
  PUSHn     R1
  MOVREL    R2, DriverBinding
  PUSHn     R2
  MOVREL    R1, gEfiDriverBindingProtocolGuid
  PUSHn     R1
  MOV       R2, R2(EFI_DRIVER_BINDING_PROTOCOL.DriverBindingHandle)
  PUSHn     R2
  MOVREL    R1, gST
  MOV       R1, @R1
  MOV       R1, @R1(EFI_SYSTEM_TABLE.BootServices)
  CALLEX    @R1(EFI_BOOT_SERVICES.InstallMultipleProtocolInterfaces)
  MOV       R0, R0(+8,+0)
  MOVREL    R1, IMPIMsg
  CMPI32eq  R7, EFI_SUCCESS
  JMPcc     CallFailed  

  MOV       R7, R6
  RET

section '.data' data readable writeable
  gST:      dq ?
  LoadedImage:
            dq ?
  CustomProtocolHandle:
            dq ?
  ImageHandle:
            dq ?
  BindingSupported_pointer:
            dq ?
  CustomProtocolInterface:
            rb EFI_CUSTOM_PROTOCOL.__size
  ComponentName:
            rb EFI_COMPONENT_NAME_PROTOCOL.__size
  ComponentName2:
            rb EFI_COMPONENT_NAME_PROTOCOL.__size
  DriverBinding:
            rb EFI_DRIVER_BINDING_PROTOCOL.__size
  gEfiLoadedImageProtocolGuid:
            EFI_GUID { 0x5b1b31a1, 0x9562, 0x11d2, { 0x8e, 0x3f, 0x00, 0xa0, 0xc9, 0x69, 0x72, 0x3b } }
  gEfiDriverBindingProtocolGuid:
            EFI_GUID { 0x18a031ab, 0xb443, 0x4d1a, { 0xa5, 0xc0, 0x0c, 0x09, 0x26, 0x1e, 0x9f, 0x71 } }
  gEfiComponentNameProtocolGuid:
            EFI_GUID { 0x107a772c, 0xd5e1, 0x11d4, { 0x9a, 0x46, 0x00, 0x90, 0x27, 0x3f, 0xc1, 0x4d } }
  gEfiComponentName2ProtocolGuid:
            EFI_GUID { 0x6a7a5cff, 0xe8d9, 0x4f70, { 0xba, 0xda, 0x75, 0xab, 0x30, 0x25, 0xce, 0x14 } }
  CustomProtocolGuid:
            EFI_GUID { 0x230aa93e, 0x3d8a, 0x4bbd, { 0x8d, 0x48, 0x77, 0xd3, 0xed, 0x9c, 0xa7, 0x9b } }
  Digits:   du "0123456789ABCDEF"
  HexStr:   du "0x12345678", 0x0D, 0x0A, 0x00
  AIMsg:    du "This driver has already been installed", 0x0D, 0x0A, 0x00
  USMsg:    du "Unexpected initial status", 0x0D, 0x0A, 0x00
  OPMsg:    du "Error OpenProtocol: ", 0x00
  IPIMsg:   du "Error InstallProtocolInterface: ", 0x00
  IMPIMsg:  du "Error InstallMultipleProtocolInterfaces: ", 0x00
  HelloMsg: du "Hello from EBC driver", 0x0D, 0x0A, 0x00
  DrvName:  du "EBC Driver v1.0", 0x00
  En:       db "en", 0x00
  Eng:      db "eng", 0x00
  
section '.reloc' fixups data discardable
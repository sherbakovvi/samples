unit KernCallBack_TLB;

// ************************************************************************ //
// WARNING                                                                    
// -------                                                                    
// The types declared in this file were generated from data read from a       
// Type Library. If this type library is explicitly or indirectly (via        
// another type library referring to this type library) re-imported, or the   
// 'Refresh' command of the Type Library Editor activated while editing the   
// Type Library, the contents of this file will be regenerated and all        
// manual modifications will be lost.                                         
// ************************************************************************ //

// PASTLWTR : 1.2
// File generated on 23.02.2008 14:14:53 from Type Library described below.

// ************************************************************************  //
// Type Lib: C:\Kernel1\KernCallBack.tlb (1)
// LIBID: {3FE280EE-C99B-4990-8A9E-7BE87F87B4B6}
// LCID: 0
// Helpfile: 
// HelpString: KernCallBack Library
// DepndLst: 
//   (1) v2.0 stdole, (C:\WINDXP\system32\stdole2.tlb)
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers. 
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
interface

uses Windows, ActiveX, Classes, Graphics, StdVCL, Variants;
  

// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:        
//   Type Libraries     : LIBID_xxxx                                      
//   CoClasses          : CLASS_xxxx                                      
//   DISPInterfaces     : DIID_xxxx                                       
//   Non-DISP interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  KernCallBackMajorVersion = 1;
  KernCallBackMinorVersion = 0;

  LIBID_KernCallBack: TGUID = '{3FE280EE-C99B-4990-8A9E-7BE87F87B4B6}';

  IID_ICallBack: TGUID = '{F77C0A84-E3E4-4945-9A25-DE08D4E8043E}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  ICallBack = interface;
  ICallBackDisp = dispinterface;

// *********************************************************************//
// Interface: ICallBack
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {F77C0A84-E3E4-4945-9A25-DE08D4E8043E}
// *********************************************************************//
  ICallBack = interface(IDispatch)
    ['{F77C0A84-E3E4-4945-9A25-DE08D4E8043E}']
    procedure EndPlayDVR(Handle: Integer); safecall;
    procedure EndSaveDVR(Handle: Integer); safecall;
    procedure Ping; safecall;
    procedure SendTo(Cmd: Integer); safecall;
  end;

// *********************************************************************//
// DispIntf:  ICallBackDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {F77C0A84-E3E4-4945-9A25-DE08D4E8043E}
// *********************************************************************//
  ICallBackDisp = dispinterface
    ['{F77C0A84-E3E4-4945-9A25-DE08D4E8043E}']
    procedure EndPlayDVR(Handle: Integer); dispid 201;
    procedure EndSaveDVR(Handle: Integer); dispid 202;
    procedure Ping; dispid 203;
    procedure SendTo(Cmd: Integer); dispid 204;
  end;

implementation

uses ComObj;

end.

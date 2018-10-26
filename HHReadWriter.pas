unit HHReadWriter;

interface

uses Windows;

const
   ERR_FILE_SUCCESS             =   0;
   ERR_FILE_INVALID_PARAMETER   =  -1;
   ERR_FILE_INVALID_FILE        =  -2;
   ERR_FILE_OPEN_FAIL           =  -3;
   ERR_FILE_INVALID             =  -4;
   ERR_FILE_NO_OPEN             =  -5;
   ERR_FILE_NO_FRAME            =  -6;
   ERR_FILE_OPER_FAIL           =  -7;
   ERR_FILE_START               =  -8;
   ERR_FILE_OVER                =  -9;
   ERR_FILE_END                 =  -10;
   ERR_STREAM_NOINI             =  -11;

type
   PPBYTE = ^PBYTE;
   eHHFrameType = (
     eType_Frame_A = $0d,
     eType_Frame_I = $0e,
  	 eType_Frame_P = $0b
   );

  THHFileFrameInfo = record
    cFrameType : char;
    dwPlayTime : DWORD;
    dwFrameSize: DWORD;
    dwAVEncType : DWORD;
    pFrameBuffer : PBYTE;
    m_PlayStatus : integer;
  end;
  {
		memset(this,0,sizeof(_tagHHFileFrameInfo));
	}

  THHFileInfo = record
      dwFrameSize: DWORD;
      dwPlayTime : DWORD;
      dwReserve : array[0..1] of DWORD;
   end;
	{
		memset(this,0,sizeof(_tagHHFileInfo));
	}

  eWriteFileStatus = (
    eStatus_CreateFileSuccess = 1,
    eStatus_CloseFileSuccess  = 2,
    eStatus_CreateFileError  = -1,
    eStatus_WriteFileError   = -2
  );

  HHWriteFileCB = function (FileName : LPCTSTR; dwStatus : DWORD; var pFileInfo : THHFILEINFO; pContext : Pointer) : Integer; stdcall;


  function  HHFile_InitReader : THandle;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_ReleaseReader(hReader : THandle) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_OpenFile(hReader : THandle; filelist : PLPSTR; filenum : Integer; var nTimeLength : DWORD) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_CloseFile(hReader : THandle) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_GetFileInfo(hReader : THandle; var dwTimeLength, dwFileLength :DWORD) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_GetFilePal(hReader : THandle; var pdwPal : DWORD) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_GetNextFrame(hReader : THandle; var xFileFrameInfo : THHFILEFRAMEINFO) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_GetNextFrame2(hReader : THandle; var cFrameType : char; ppFrameBuffer : PPBYTE; var dwFrameSize, dwEncType, dwPlayTime : DWORD) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_GetPosition(hReader : THandle; var dwPlayedTime : DWORD) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_SetPosition(hReader : THandle; fOffset : Single) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_SeekToSecond(hReader : THandle; nSec : integer) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_SetLoop(hReader : THandle; bIsLoop : BOOL = True) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_SetReadOrder(hReader : THandle; bIsOrder : BOOL = True) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_SetReadKeyFrame(hReader : THandle; bIsKeyFrame : BOOL = False) : integer;
    stdcall; external 'HHReadWriterSDK.dll';


  function  HHFile_InitWriter : THandle;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_ReleaseWriter(hWriter : THandle) : integer;
    stdcall; external 'HHReadWriterSDK.dll';

  function  HHFile_SetCacheBufferSize(hWriter : THandle; lBufferSize : LongWord = 500 * 1024) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_RegWriteFileCB(hWriter : THandle; pCBWriteFile : HHWriteFileCB; pContext : Pointer = nil) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_InputFrame(hWriter : THandle; pFrame : PByte; lFrameSize : LongWord; dwEncType : DWORD = 0) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_StartWrite(hWriter : THandle;  FileName : LPCTSTR) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_GetWriteInfo(hWriter : THandle; var xFileInfo : THHFILEINFO) : integer;
    stdcall; external 'HHReadWriterSDK.dll';
  function  HHFile_StopWrite(hWriter : THandle) : integer;
    stdcall; external 'HHReadWriterSDK.dll';

implementation

end.
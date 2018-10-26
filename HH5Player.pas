unit HH5Player;

interface

uses Windows;

const
  HH5PLAYER_MAX_PLAYER = 128; // ������������ �� 128 <nPort = 0 ~ 127>
  HH5PLAYER_MSG_PLAY_END = $FFFFFFFF;

  function HH5PLAYER_InitSDK(hHwnd : HWND) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_ReleaseSDK : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function  HH5PLAYER_InitPlayer(NPort : WORD; hHwnd : HWND) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_ReleasePlayer(NPort : WORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';

  function HH5PLAYER_OpenStreamFileM(NPort : WORD; FileList : PLPSTR; FileNum : Integer; var nTimeLength : DWORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_GetStreamFileInfo(NPort : WORD; var dwTimeLength, dwFileLength, dwWidth, dwHeight : DWORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_Play(NPort : WORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_FastPlay(NPort : WORD;  nValue : DWORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_FastPlayBack(NPort : WORD; nValue : DWORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_FrameGO(NPort : WORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_FrameBack(NPort : WORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_Pause(NPort : WORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_Resume(NPort : WORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_Stop(NPort : WORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_GetPlayPosition(NPort : WORD; var dwPlayedTime : DWORD) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_SetPlayPosition(NPort : WORD; fOffset : Single) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_SeekToSecond(NPort : WORD; nSec : integer) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_SetPlayLoop(NPort : WORD; bIsLoop : BOOL) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_RegPlayStatusMsg(NPort : WORD; HWND : HWND; MessageID : UINT) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_SetAudio(NPort : DWORD; bEnabled : BOOL) : integer;
    stdcall; external 'HH5PlayerSDK.dll';
  function HH5PLAYER_CaptureOnePicture(NPort : WORD; bmpbuf : PPointer; var bmpsize : integer) : integer;
    stdcall; external 'HH5PlayerSDK.dll';

{
//------------------------------ 3, ��� ���� -------------- --------------------//
/ / �������� ����������
DLLEXPORT_API Int __stdcall HH5PLAYER_OpenStream (WORD NPort);
/ / ���������
DLLEXPORT_API Int __stdcall HH5PLAYER_PutDecStreamData (WORD NPort, PByte pBuf, DWORD nSize, Int nDataType);
/ / ���� ����������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_PutDecStreamDataEx (WORD NPort, PByte pBuf, DWORD nSize, UINT nDataType, HH5KAV_INFO * pAVInfo);
/ / ���� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_StopStream (WORD NPort);
/ / ������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_CloseStream (WORD NPort);
/ / �������� ������ �����
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamFrameSize (WORD NPort);
/ / �������� ����� ������ �����
DLLEXPORT_API Int __stdcall HH5PLAYER_GetAudioFrameSize (WORD NPort);
/ / ���������� �������� ���������������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetStreamPlaySpeed ??(WORD NPort, WORD nSpeed);
/ / �������� �������� ���������������
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamPlaySpeed ??(WORD NPort);
/ / ���������� �������� ��������������� 2, FValue: ����� ���� � �����, ����� ���: 40 ��, 33.3ms, bDelayAdjust: �������� �� ���� ��������� ������, ���������� ������� (����������: ���� �������� ����� �� ����, ������ ���� ���������� � FALSE)
DLLEXPORT_API Int HH5PLAYER_SetStreamPlaySpeed2 __stdcall (WORD NPort, ������� FValue, BOOL bDelayAdjust = TRUE);

//------------------------------ 4, ������ ������������ ������� ------------- ---------------------//
/ / ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_SetAudio (WORD NPort, BOOL bEnabled);
/ / �������� �����������
DLLEXPORT_API Int __stdcall HH5PLAYER_UpDateImage (WORD NPort);
/ / �������� ������ �������
DLLEXPORT_API Int __stdcall HH5PLAYER_UpdateBounds (WORD NPort);
/ / ���������� �������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayhWnd (WORD NPort, HWND HWND);
/ / ������� ���������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetPartDisplay (WORD NPort, HWND hPartWnd, RECT * pPartRect);
/ / ������ �������� �����������
DLLEXPORT_API Int __stdcall HH5PLAYER_CaptureOnePicture (WORD NPort, ���������������� ** bmpbuf, Int & bmpsize);
/ / �������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_GetVolume (WORD NPort, ����� lpVolume *);
/ / ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_SetVolume (WORD NPort, ����� lVolume);
/ / �������� ��������� �������� 0: ������� 1: ������ ��������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDecoderQulity (BOOL bQulity);
/ / Display Control bZoomIn: ������� �����, bDeInterlace: ����������� ������������� ������, bPlayMode TRUE FALSE ������� ��������� ��������� ������� ���������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDecoderParam (BOOL bZoomIn, BOOL bDeInterlace, BOOL bPlayMode = FALSE);
/ / ����� �������� ��-������, ������������ ������ (1 � 60)
DLLEXPORT_API Int __stdcall HH5PLAYER_SetVideoBufferSize (INT nFrameNum = 15);
/ / ������� ��� ���
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearAllBuffer (WORD NPort);
/ / �������� �����������
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearVideoBuffer (WORD NPort);
/ / �������� ����� ������
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearAudioBuffer (WORD NPort);
/ / ������� ����������� DirctX
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearImage (WORD NPort, DWORD dwColor = 0);


//------------------------------ 5 ------------- Audio Codec ---------------------//
/ / Audio Coding
DLLEXPORT_API Int __stdcall HH5PLAYER_AudioEncodeData (������������� * BuffIn, Int InNum, BYTE * Buffout);
/ / ����� �������
DLLEXPORT_API Int __stdcall HH5PLAYER_AudioDecodeData (BYTE * BuffIn, Int InNum, ������������� * Buffout);

/ / G.726 ����� ����������� �� ��������� G.726 16Kbps
DLLEXPORT_API Int __stdcall HH5PLAYER_G726AEncodeData (������������� * BuffIn, Int InNum, BYTE * Buffout);
/ / G.726 ����� ��������
DLLEXPORT_API Int __stdcall HH5PLAYER_G726ADecodeData (BYTE * BuffIn, Int InNum, ������������� * Buffout);

# ���������� HH5PLAYER_G722AEncodeData HH5PLAYER_AudioEncodeData
# ���������� HH5PLAYER_G722ADecodeData HH5PLAYER_AudioDecodeData

/************************************************* ****************************/
/******************************** �-�������, ����� ��������� ������� *********** **************/
/************************************************* ****************************/

//------------------------------ 1, ����� ������� 1: ����� ����� -------- --------------------------//
/ / Pin HH98 � HH58 ����� ������������� ��������� ����������, ������� ����� ����� G.711 G.726 ADPCM ������

/ / Audio Coding ����������
DLLEXPORT_API Int __stdcall HH5PLAYER_AudioEncodeDataEx (������������� * BuffIn, Int InNum, BYTE * Buffout, UINT nEncodeType, UINT nBitrate);
/ / ����� ���������� �������
DLLEXPORT_API Int __stdcall HH5PLAYER_AudioDecodeDataEx (BYTE * BuffIn, Int InNum, ������������� * Buffout, UINT nEncodeType, UINT nBitrate);

//------------------------------ 2, ����� ������� 2: ������������� ����� � ����� �������� ------ ----------------------------//
/ / ����� ����� ������������� H.264 nVersion 1: ������ (123), 2: ����� (125)
DLLEXPORT_API Int __stdcall HH5PLAYER_SelectH264 (WORD NPort, UINT nVersion);
/ / Anti-���������� ������������� ������: �� ���������: ��������
DLLEXPORT_API Int __stdcall HH5PLAYER_WaitForVerticalBlank (BOOL bWait = False);

/ / ����������: ���� �� ������ �������� ����������� �� ����� �����������, �������� �����, � �.�., ����������, ����������� ��������� ������� ������������� ������, � bSupportDraw �������� "������" (� ���� ������������� ��� ��������� ������� ��� ���������� HDC)
/ / ������������� Play 2
DLLEXPORT_API Int HH5PLAYER_InitPlayer2 __stdcall (WORD NPort, HWND HWND, BOOL bSupportDraw = False);
/ / ������������� ������
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawImage (WORD NPort, Int �, � Int, ������������� ������ pBmpImage *, Int nSize);
/ / ������������� ������ OSD
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawText (WORD NPort, Int �, � Int, ������ pszText *, LOGFONT �����, COLORREF crText, COLORREF crBack = -1 / * crBack -1: ���������� * /);
/ / ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDrawPen (WORD NPort, Int nPenStyle, Int nWidth, COLORREF crColor);
/ / ������ �����
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawLine (WORD NPort, Int x1, y1 Int, Int x2, y2 Int);
/ / Frame
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawRect (WORD NPort, Int x1, y1 Int, Int x2, y2 Int);
/ / �������� �������
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearDraw (WORD NPort, Int nType); / / nType: 0 ���, 1 �����������, 2 ������, 3 �����, �������������

������� Int (WINAPI * HHCBOnDraw) (WORD NPort, HDC HDC, Int nWidth, Int nHeight, pContext ����������������� *); / / HDC ��������� ��� ������� �������
DLLEXPORT_API Int __stdcall HH5PLAYER_RegCBOnDraw (WORD NPort, HHCBOnDraw pCBOnDraw, ���������������� * pContext = NULL);

//------------------------------ 3, ����� ������� 2: �������� --------- -------------------------//
������� Int (WINAPI * HHTalkCaptureData) (BYTE * ���������� �����, Int nBufLen, DWORD dwContext = 0, ���������������� * pContext = NULL);
/ / ������������� ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_TKInit (HWND HWnd, ����� � hTalk);
DLLEXPORT_API Int __stdcall HH5PLAYER_TKRegCaptureDataCB (HANDLE hTalk, HHTalkCaptureData pCBTalk, DWORD dwContext = 0, ���������������� * pContext = NULL);

/ / �������� ��������
DLLEXPORT_API Int __stdcall HH5PLAYER_TKStart (HANDLE hTalk, WaveFormatEx * pInFormat, WaveFormatEx * pOutFormat);
/ / ����� ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_TKStop (HANDLE hTalk);
/ / �������� ������ �� ������� ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_TKSendToPCData (HANDLE hTalk, BYTE * ���������� �����, Int nBufLen);
/ / ���������� ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_TKSetVolume (HANDLE hTalk, ����� lVolume);
/ / �������� ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_TKGetVolume (HANDLE hTalk, ����� lpVolume *);
/ / �������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_TKRelease (HANDLE hTalk);

/************************************************* ****************************/
/******************************* �-���������, ������ �� �������������� ������� *********** *************/
/************************************************* ****************************/
//================================================ ================
/ / � ����� ������ �� �������������� �������
/ / 1. �������������� ����� �������������� ���������� ���������
/ / 2. ���������������� ������������� �����������, �������� �����, � �.�., ����� ���� ���������� � ������� ����� �������
//================================================ ================
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayGUID (������ pGuid *);
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayGUIDEx (WORD NPort, ������ pGuid *);
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayWndEx (WORD NPort, ������������� nFirstScreenWidth Int);

������� Int (WINAPI * YUVDataCallBack) (WORD NPort,
������������� ������ * YBuf,
������������� ������ * UBuf,
������������� ������ * VBuf,
������������� Int nYStride,
������������� Int nUVStride,
������������� Int nWidth,
������������� Int nHeight,
������������� nViFormat Int
);

DLLEXPORT_API Int __stdcall HH5PLAYER_RegYUVDataCallBack (YUVDataCallBack pYUVDataCallBack, BOOL nDispImage);

������� Int (WINAPI * DrawImageCallBack) (WORD NPort,
HDC HDC,
������������� ������ pDispBuf *,
������������� Int nStride,
������������� nDDrawMode Int
);
DLLEXPORT_API Int __stdcall HH5PLAYER_RegDrawImageCallBack (DrawImageCallBack pDrawImageCallBack);
}
implementation

end.




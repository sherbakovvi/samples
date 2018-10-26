������������ ������ HH5PlayerSDK.h
/************************************************* *****************************
* �������� �������: HH5PlayerSDK
* �������� �����: HH5PlayerSDK.h
* ������: V5.5.0.1
* ����������: ���� ������ ������������ ����� � ����� ������������� � ��������������� �������

* ����: 15 ������ 2005
��������� ����������:
* ������ ����������: ���
************************************************** ****************************/
# IFNDEF HH5PLAYERSDK_H
# ���������� HH5PLAYERSDK_H

# ���������� DLLEXPORT_API ������� "C" __declspec (dllexport)

# �������� <mmsystem.h>
# �������� "HHAVDefine.h"

/************************************************* ****************************/
/********************************* ���� ������ ************ ******************/
/************************************************* ****************************/
# ���������� HH5PLAYER_MAX_PLAER 128 / / ������������ �� 128 <nPort = 0 ~ 127>

# ���������� HH5PLAYER_MSG_PLAY_END 0xFFFFFFFF / / ��������� ����������� <file �����> ���������������
/ / Non-0xFFFFFFFF: �������� ����: 0 ����� (� ��������)
������� HHAV_INFO HH5KAV_INFO;
������� PHHAV_INFO PHH5KAV_INFO;

/************************************************* ****************************/
/******************************** ��-������, ����������� ������� ���������� ************ *************/
/************************************************* ****************************/

//------------------------------ 1, ����� �������������, ����� --------- -------------------------//
/ / ������������� SDK ��������
DLLEXPORT_API Int __stdcall HH5PLAYER_InitSDK (HWND hHwnd);
/ / ������ SDK ��������
DLLEXPORT_API Int HH5PLAYER_ReleaseSDK __stdcall ();
/ / ������������� ������ (��. HH5PLAYER_InitPlayer2)
DLLEXPORT_API Int __stdcall HH5PLAYER_InitPlayer (USHORT NPort, HWND HWND);
/ / ���������� Player
DLLEXPORT_API Int __stdcall HH5PLAYER_ReleasePlayer (USHORT NPort);

//------------------------------ 2 ��������������� ����� -------------- --------------------//
/ / ������� ����
DLLEXPORT_API Int __stdcall HH5PLAYER_OpenStreamFileM (USHORT NPort, LPCTSTR ������ ������ [], Int �����, DWORD � nTimeLength);
/ / �������� ���������� � �����
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamFileInfo (USHORT NPort, DWORD * dwTimeLength, DWORD * dwFileLength, DWORD * dwWidth, DWORD * dwHeight);
/ / �������
DLLEXPORT_API Int __stdcall HH5PLAYER_Play (USHORT NPort);
/ / ������� ���� dwValue 1 --- 1000 �� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_FastPlay (USHORT NPort, DWORD nValue);
/ / ���� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_FastPlayBack (USHORT NPort, DWORD nValue);
/ / ��������� ���� �
DLLEXPORT_API Int __stdcall HH5PLAYER_FrameGO (USHORT NPort);
/ / ��������� ���� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_FrameBack (USHORT NPort);
/ / �����
DLLEXPORT_API Int __stdcall HH5PLAYER_Pause (USHORT NPort);
/ / �����������
DLLEXPORT_API Int __stdcall HH5PLAYER_Resume (USHORT NPort);
/ / ����
DLLEXPORT_API Int __stdcall HH5PLAYER_Stop (USHORT NPort);
/ / �������� ����� ���������������
DLLEXPORT_API Int __stdcall HH5PLAYER_GetPlayPosition (USHORT NPort, DWORD * dwPlayedTime);
/ / ���������� ������� ���������������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetPlayPosition (USHORT NPort, ������� fOffset);
/ / ����������� ��������� �� ��������� ������ �������
DLLEXPORT_API Int __stdcall HH5PLAYER_SeekToSecond (USHORT NPort, Int ����);
/ / ����
DLLEXPORT_API Int __stdcall HH5PLAYER_SetPlayLoop (USHORT NPort, BOOL bIsLoop);
/ / �� ���� ������ ��������� (1.H5PLAYER_MSG_PLAY_END: ??��������������� ������ ����� 2 ��������� ���������������:. 0 ���� � ������ <)
DLLEXPORT_API Int __stdcall HH5PLAYER_RegPlayStatusMsg (USHORT NPort, HWND HWND, UINT MessageID);


//------------------------------ 3, ��� ���� -------------- --------------------//
/ / �������� ����������
DLLEXPORT_API Int __stdcall HH5PLAYER_OpenStream (USHORT NPort);
/ / ���������
DLLEXPORT_API Int __stdcall HH5PLAYER_PutDecStreamData (USHORT NPort, PByte pBuf, DWORD nSize, Int nDataType);
/ / ���� ����������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_PutDecStreamDataEx (USHORT NPort, PByte pBuf, DWORD nSize, UINT nDataType, HH5KAV_INFO * pAVInfo);
/ / ���� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_StopStream (USHORT NPort);
/ / ������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_CloseStream (USHORT NPort);
/ / �������� ������ �����
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamFrameSize (USHORT NPort);
/ / �������� ����� ������ �����
DLLEXPORT_API Int __stdcall HH5PLAYER_GetAudioFrameSize (USHORT NPort);
/ / ���������� �������� ���������������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetStreamPlaySpeed ??(USHORT NPort, USHORT nSpeed);
/ / �������� �������� ���������������
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamPlaySpeed ??(USHORT NPort);
/ / ���������� �������� ��������������� 2, FValue: ����� ���� � �����, ����� ���: 40 ��, 33.3ms, bDelayAdjust: �������� �� ���� ��������� ������, ���������� ������� (����������: ���� �������� ����� �� ����, ������ ���� ���������� � FALSE)
DLLEXPORT_API Int HH5PLAYER_SetStreamPlaySpeed2 __stdcall (USHORT NPort, ������� FValue, BOOL bDelayAdjust = TRUE);

//------------------------------ 4, ������ ������������ ������� ------------- ---------------------//
/ / ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_SetAudio (USHORT NPort, BOOL bEnabled);
/ / �������� �����������
DLLEXPORT_API Int __stdcall HH5PLAYER_UpDateImage (USHORT NPort);
/ / �������� ������ �������
DLLEXPORT_API Int __stdcall HH5PLAYER_UpdateBounds (USHORT NPort);
/ / ���������� �������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayhWnd (USHORT NPort, HWND HWND);
/ / ������� ���������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetPartDisplay (USHORT NPort, HWND hPartWnd, RECT * pPartRect);
/ / ������ �������� �����������
DLLEXPORT_API Int __stdcall HH5PLAYER_CaptureOnePicture (USHORT NPort, ���������������� ** bmpbuf, Int & bmpsize);
/ / �������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_GetVolume (USHORT NPort, ����� lpVolume *);
/ / ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_SetVolume (USHORT NPort, ����� lVolume);
/ / �������� ��������� �������� 0: ������� 1: ������ ��������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDecoderQulity (BOOL bQulity);
/ / Display Control bZoomIn: ������� �����, bDeInterlace: ����������� ������������� ������, bPlayMode TRUE FALSE ������� ��������� ��������� ������� ���������
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDecoderParam (BOOL bZoomIn, BOOL bDeInterlace, BOOL bPlayMode = FALSE);
/ / ����� �������� ��-������, ������������ ������ (1 � 60)
DLLEXPORT_API Int __stdcall HH5PLAYER_SetVideoBufferSize (INT nFrameNum = 15);
/ / ������� ��� ���
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearAllBuffer (USHORT NPort);
/ / �������� �����������
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearVideoBuffer (USHORT NPort);
/ / �������� ����� ������
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearAudioBuffer (USHORT NPort);
/ / ������� ����������� DirctX
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearImage (USHORT NPort, DWORD dwColor = 0);


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
DLLEXPORT_API Int __stdcall HH5PLAYER_SelectH264 (USHORT NPort, UINT nVersion);
/ / Anti-���������� ������������� ������: �� ���������: ��������
DLLEXPORT_API Int __stdcall HH5PLAYER_WaitForVerticalBlank (BOOL bWait = False);

/ / ����������: ���� �� ������ �������� ����������� �� ����� �����������, �������� �����, � �.�., ����������, ����������� ��������� ������� ������������� ������, � bSupportDraw �������� "������" (� ���� ������������� ��� ��������� ������� ��� ���������� HDC)
/ / ������������� Play 2
DLLEXPORT_API Int HH5PLAYER_InitPlayer2 __stdcall (USHORT NPort, HWND HWND, BOOL bSupportDraw = False);
/ / ������������� ������
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawImage (USHORT NPort, Int �, � Int, ������������� ������ pBmpImage *, Int nSize);
/ / ������������� ������ OSD
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawText (USHORT NPort, Int �, � Int, ������ pszText *, LOGFONT �����, COLORREF crText, COLORREF crBack = -1 / * crBack -1: ���������� * /);
/ / ���������� �����
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDrawPen (USHORT NPort, Int nPenStyle, Int nWidth, COLORREF crColor);
/ / ������ �����
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawLine (USHORT NPort, Int x1, y1 Int, Int x2, y2 Int);
/ / Frame
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawRect (USHORT NPort, Int x1, y1 Int, Int x2, y2 Int);
/ / �������� �������
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearDraw (USHORT NPort, Int nType); / / nType: 0 ���, 1 �����������, 2 ������, 3 �����, �������������

������� Int (WINAPI * HHCBOnDraw) (USHORT NPort, HDC HDC, Int nWidth, Int nHeight, pContext ����������������� *); / / HDC ��������� ��� ������� �������
DLLEXPORT_API Int __stdcall HH5PLAYER_RegCBOnDraw (USHORT NPort, HHCBOnDraw pCBOnDraw, ���������������� * pContext = NULL);

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
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayGUIDEx (USHORT NPort, ������ pGuid *);
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayWndEx (USHORT NPort, ������������� nFirstScreenWidth Int);

������� Int (WINAPI * YUVDataCallBack) (USHORT NPort,
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

������� Int (WINAPI * DrawImageCallBack) (USHORT NPort,
HDC HDC,
������������� ������ pDispBuf *,
������������� Int nStride,
������������� nDDrawMode Int
);
DLLEXPORT_API Int __stdcall HH5PLAYER_RegDrawImageCallBack (DrawImageCallBack pDrawImageCallBack);


# Endif

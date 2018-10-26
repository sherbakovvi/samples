unit HH5Player;

interface

uses Windows;

const
  HH5PLAYER_MAX_PLAYER = 128; // декодировать до 128 <nPort = 0 ~ 127>
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
//------------------------------ 3, ход игры -------------- --------------------//
/ / Открытие потокового
DLLEXPORT_API Int __stdcall HH5PLAYER_OpenStream (WORD NPort);
/ / Видеовход
DLLEXPORT_API Int __stdcall HH5PLAYER_PutDecStreamData (WORD NPort, PByte pBuf, DWORD nSize, Int nDataType);
/ / Ввод расширенных видео
DLLEXPORT_API Int __stdcall HH5PLAYER_PutDecStreamDataEx (WORD NPort, PByte pBuf, DWORD nSize, UINT nDataType, HH5KAV_INFO * pAVInfo);
/ / Стоп видео
DLLEXPORT_API Int __stdcall HH5PLAYER_StopStream (WORD NPort);
/ / Закрыть видео
DLLEXPORT_API Int __stdcall HH5PLAYER_CloseStream (WORD NPort);
/ / Получить размер кадра
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamFrameSize (WORD NPort);
/ / Получить аудио размер кадра
DLLEXPORT_API Int __stdcall HH5PLAYER_GetAudioFrameSize (WORD NPort);
/ / Установить скорость воспроизведения
DLLEXPORT_API Int __stdcall HH5PLAYER_SetStreamPlaySpeed ??(WORD NPort, WORD nSpeed);
/ / Получить скорость воспроизведения
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamPlaySpeed ??(WORD NPort);
/ / Установить скорость воспроизведения 2, FValue: время игры в кадре, такие как: 40 мс, 33.3ms, bDelayAdjust: является ли Есть выпадения кадров, калибровки времени (Примечание: Если ключевые кадры из игры, должен быть установлен в FALSE)
DLLEXPORT_API Int HH5PLAYER_SetStreamPlaySpeed2 __stdcall (WORD NPort, плавать FValue, BOOL bDelayAdjust = TRUE);

//------------------------------ 4, прочие операционные игроков ------------- ---------------------//
/ / Установить аудио
DLLEXPORT_API Int __stdcall HH5PLAYER_SetAudio (WORD NPort, BOOL bEnabled);
/ / Обновить изображение
DLLEXPORT_API Int __stdcall HH5PLAYER_UpDateImage (WORD NPort);
/ / Обновить границ дисплее
DLLEXPORT_API Int __stdcall HH5PLAYER_UpdateBounds (WORD NPort);
/ / Установить дисплее
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayhWnd (WORD NPort, HWND HWND);
/ / Местные Увеличить
DLLEXPORT_API Int __stdcall HH5PLAYER_SetPartDisplay (WORD NPort, HWND hPartWnd, RECT * pPartRect);
/ / Захват текущего изображения
DLLEXPORT_API Int __stdcall HH5PLAYER_CaptureOnePicture (WORD NPort, недействительным ** bmpbuf, Int & bmpsize);
/ / Получить объем
DLLEXPORT_API Int __stdcall HH5PLAYER_GetVolume (WORD NPort, долго lpVolume *);
/ / Установить объем
DLLEXPORT_API Int __stdcall HH5PLAYER_SetVolume (WORD NPort, долго lVolume);
/ / Показать настройки качества 0: высокая 1: низкое качество
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDecoderQulity (BOOL bQulity);
/ / Display Control bZoomIn: большой экран, bDeInterlace: Потребители чересстрочной зигзаг, bPlayMode TRUE FALSE гладкой приоритет реального времени приоритет
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDecoderParam (BOOL bZoomIn, BOOL bDeInterlace, BOOL bPlayMode = FALSE);
/ / Когда беглости во-первых, кэшированных кадров (1 к 60)
DLLEXPORT_API Int __stdcall HH5PLAYER_SetVideoBufferSize (INT nFrameNum = 15);
/ / Очищаем все кэш
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearAllBuffer (WORD NPort);
/ / Очистить видеобуфера
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearVideoBuffer (WORD NPort);
/ / Очистить аудио буфера
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearAudioBuffer (WORD NPort);
/ / Очищаем поверхность DirctX
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearImage (WORD NPort, DWORD dwColor = 0);


//------------------------------ 5 ------------- Audio Codec ---------------------//
/ / Audio Coding
DLLEXPORT_API Int __stdcall HH5PLAYER_AudioEncodeData (неподписанным * BuffIn, Int InNum, BYTE * Buffout);
/ / Аудио декодер
DLLEXPORT_API Int __stdcall HH5PLAYER_AudioDecodeData (BYTE * BuffIn, Int InNum, неподписанным * Buffout);

/ / G.726 аудио кодирования по умолчанию G.726 16Kbps
DLLEXPORT_API Int __stdcall HH5PLAYER_G726AEncodeData (неподписанным * BuffIn, Int InNum, BYTE * Buffout);
/ / G.726 аудио декодера
DLLEXPORT_API Int __stdcall HH5PLAYER_G726ADecodeData (BYTE * BuffIn, Int InNum, неподписанным * Buffout);

# Определить HH5PLAYER_G722AEncodeData HH5PLAYER_AudioEncodeData
# Определить HH5PLAYER_G722ADecodeData HH5PLAYER_AudioDecodeData

/************************************************* ****************************/
/******************************** В-третьих, новый интерфейс функции *********** **************/
/************************************************* ****************************/

//------------------------------ 1, новая функция 1: Аудио кодек -------- --------------------------//
/ / Pin HH98 и HH58 Серия предоставляет интерфейс устройства, которые могут кодек G.711 G.726 ADPCM формат

/ / Audio Coding расширение
DLLEXPORT_API Int __stdcall HH5PLAYER_AudioEncodeDataEx (неподписанным * BuffIn, Int InNum, BYTE * Buffout, UINT nEncodeType, UINT nBitrate);
/ / Аудио расширение декодер
DLLEXPORT_API Int __stdcall HH5PLAYER_AudioDecodeDataEx (BYTE * BuffIn, Int InNum, неподписанным * Buffout, UINT nEncodeType, UINT nBitrate);

//------------------------------ 2, новая функция 2: декодирования видео и видео операции ------ ----------------------------//
/ / Выбор новых декодирования H.264 nVersion 1: старый (123), 2: новый (125)
DLLEXPORT_API Int __stdcall HH5PLAYER_SelectH264 (WORD NPort, UINT nVersion);
/ / Anti-разрушения переключатель ложной: от истинного: открытый
DLLEXPORT_API Int __stdcall HH5PLAYER_WaitForVerticalBlank (BOOL bWait = False);

/ / Примечание: Если вы хотите наложить изображения на видео изображение, рисовать линии, и т.д., пожалуйста, используйте следующие функции инициализации плеера, и bSupportDraw значение "истина" (в окно проигрывателя для поддержки внешних или внутренних HDC)
/ / Инициализация Play 2
DLLEXPORT_API Int HH5PLAYER_InitPlayer2 __stdcall (WORD NPort, HWND HWND, BOOL bSupportDraw = False);
/ / Воспроизвести краски
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawImage (WORD NPort, Int х, у Int, неподписанные символ pBmpImage *, Int nSize);
/ / Воспроизвести текста OSD
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawText (WORD NPort, Int х, у Int, символ pszText *, LOGFONT футов, COLORREF crText, COLORREF crBack = -1 / * crBack -1: прозрачный * /);
/ / Установить щетки
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDrawPen (WORD NPort, Int nPenStyle, Int nWidth, COLORREF crColor);
/ / Рисуем линию
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawLine (WORD NPort, Int x1, y1 Int, Int x2, y2 Int);
/ / Frame
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawRect (WORD NPort, Int x1, y1 Int, Int x2, y2 Int);
/ / Очистить дисплей
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearDraw (WORD NPort, Int nType); / / nType: 0 все, 1 изображение, 2 текста, 3 линия, прямоугольник

ЬурейеЕ Int (WINAPI * HHCBOnDraw) (WORD NPort, HDC HDC, Int nWidth, Int nHeight, pContext недействительными *); / / HDC поддержка для внешних вызовов
DLLEXPORT_API Int __stdcall HH5PLAYER_RegCBOnDraw (WORD NPort, HHCBOnDraw pCBOnDraw, недействительным * pContext = NULL);

//------------------------------ 3, новая функция 2: Интерком --------- -------------------------//
ЬурейеЕ Int (WINAPI * HHTalkCaptureData) (BYTE * пиксельный буфер, Int nBufLen, DWORD dwContext = 0, недействительным * pContext = NULL);
/ / Инициализация внутренней связи
DLLEXPORT_API Int __stdcall HH5PLAYER_TKInit (HWND HWnd, ручка и hTalk);
DLLEXPORT_API Int __stdcall HH5PLAYER_TKRegCaptureDataCB (HANDLE hTalk, HHTalkCaptureData pCBTalk, DWORD dwContext = 0, недействительным * pContext = NULL);

/ / Начинаем говорить
DLLEXPORT_API Int __stdcall HH5PLAYER_TKStart (HANDLE hTalk, WaveFormatEx * pInFormat, WaveFormatEx * pOutFormat);
/ / Конец внутренней связи
DLLEXPORT_API Int __stdcall HH5PLAYER_TKStop (HANDLE hTalk);
/ / Передача данных по местным внутренней связи
DLLEXPORT_API Int __stdcall HH5PLAYER_TKSendToPCData (HANDLE hTalk, BYTE * пиксельный буфер, Int nBufLen);
/ / Установить внутренней аудио
DLLEXPORT_API Int __stdcall HH5PLAYER_TKSetVolume (HANDLE hTalk, долго lVolume);
/ / Получить внутренней аудио
DLLEXPORT_API Int __stdcall HH5PLAYER_TKGetVolume (HANDLE hTalk, долго lpVolume *);
/ / Интерком релиз
DLLEXPORT_API Int __stdcall HH5PLAYER_TKRelease (HANDLE hTalk);

/************************************************* ****************************/
/******************************* В-четвертых, больше не поддерживаются функции *********** *************/
/************************************************* ****************************/
//================================================ ================
/ / В новой версии не поддерживаются функции
/ / 1. Дополнительные карты поддерживается внутренней обработки
/ / 2. Видеоизображение накладываются изображения, рисовать линии, и т.д., может быть достигнута с помощью новых функций
//================================================ ================
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayGUID (символ pGuid *);
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayGUIDEx (WORD NPort, символ pGuid *);
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayWndEx (WORD NPort, неподписанные nFirstScreenWidth Int);

ЬурейеЕ Int (WINAPI * YUVDataCallBack) (WORD NPort,
неподписанные символ * YBuf,
неподписанные символ * UBuf,
неподписанные символ * VBuf,
неподписанных Int nYStride,
неподписанных Int nUVStride,
неподписанных Int nWidth,
неподписанных Int nHeight,
неподписанных nViFormat Int
);

DLLEXPORT_API Int __stdcall HH5PLAYER_RegYUVDataCallBack (YUVDataCallBack pYUVDataCallBack, BOOL nDispImage);

ЬурейеЕ Int (WINAPI * DrawImageCallBack) (WORD NPort,
HDC HDC,
неподписанные символ pDispBuf *,
неподписанных Int nStride,
неподписанных nDDrawMode Int
);
DLLEXPORT_API Int __stdcall HH5PLAYER_RegDrawImageCallBack (DrawImageCallBack pDrawImageCallBack);
}
implementation

end.




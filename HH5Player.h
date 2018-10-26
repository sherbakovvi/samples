Переведенная версия HH5PlayerSDK.h
/************************************************* *****************************
* Название системы: HH5PlayerSDK
* Название файла: HH5PlayerSDK.h
* Версия: V5.5.0.1
* Примечание: Этот модуль обеспечивает аудио и видео декодирования и воспроизведения дисплей

* Дата: 15 апреля 2005
Последнее обновление:
* Другие примечания: Нет
************************************************** ****************************/
# IFNDEF HH5PLAYERSDK_H
# Определить HH5PLAYERSDK_H

# Определить DLLEXPORT_API Экстерн "C" __declspec (dllexport)

# Включить <mmsystem.h>
# Включить "HHAVDefine.h"

/************************************************* ****************************/
/********************************* Один макрос ************ ******************/
/************************************************* ****************************/
# Определить HH5PLAYER_MAX_PLAER 128 / / декодировать до 128 <nPort = 0 ~ 127>

# Определить HH5PLAYER_MSG_PLAY_END 0xFFFFFFFF / / Сообщение определение <file конец> воспроизведения
/ / Non-0xFFFFFFFF: прогресс игры: 0 время (в секундах)
ЬурейеЕ HHAV_INFO HH5KAV_INFO;
ЬурейеЕ PHHAV_INFO PHH5KAV_INFO;

/************************************************* ****************************/
/******************************** Во-вторых, определение функции интерфейса ************ *************/
/************************************************* ****************************/

//------------------------------ 1, игрок инициализации, релиз --------- -------------------------//
/ / Инициализация SDK ресурсов
DLLEXPORT_API Int __stdcall HH5PLAYER_InitSDK (HWND hHwnd);
/ / Релиза SDK ресурсов
DLLEXPORT_API Int HH5PLAYER_ReleaseSDK __stdcall ();
/ / Инициализация игрока (см. HH5PLAYER_InitPlayer2)
DLLEXPORT_API Int __stdcall HH5PLAYER_InitPlayer (USHORT NPort, HWND HWND);
/ / Освободить Player
DLLEXPORT_API Int __stdcall HH5PLAYER_ReleasePlayer (USHORT NPort);

//------------------------------ 2 воспроизведения файла -------------- --------------------//
/ / Открыть файл
DLLEXPORT_API Int __stdcall HH5PLAYER_OpenStreamFileM (USHORT NPort, LPCTSTR Список файлов [], Int НОМЕР, DWORD и nTimeLength);
/ / Получить информацию о файле
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamFileInfo (USHORT NPort, DWORD * dwTimeLength, DWORD * dwFileLength, DWORD * dwWidth, DWORD * dwHeight);
/ / Слушать
DLLEXPORT_API Int __stdcall HH5PLAYER_Play (USHORT NPort);
/ / Быстрая игра dwValue 1 --- 1000 мс между
DLLEXPORT_API Int __stdcall HH5PLAYER_FastPlay (USHORT NPort, DWORD nValue);
/ / Блок назад
DLLEXPORT_API Int __stdcall HH5PLAYER_FastPlayBack (USHORT NPort, DWORD nValue);
/ / Одиночный кадр в
DLLEXPORT_API Int __stdcall HH5PLAYER_FrameGO (USHORT NPort);
/ / Одиночный кадр назад
DLLEXPORT_API Int __stdcall HH5PLAYER_FrameBack (USHORT NPort);
/ / Пауза
DLLEXPORT_API Int __stdcall HH5PLAYER_Pause (USHORT NPort);
/ / Продолжение
DLLEXPORT_API Int __stdcall HH5PLAYER_Resume (USHORT NPort);
/ / Стоп
DLLEXPORT_API Int __stdcall HH5PLAYER_Stop (USHORT NPort);
/ / Получить время воспроизведения
DLLEXPORT_API Int __stdcall HH5PLAYER_GetPlayPosition (USHORT NPort, DWORD * dwPlayedTime);
/ / Установить позицию воспроизведения
DLLEXPORT_API Int __stdcall HH5PLAYER_SetPlayPosition (USHORT NPort, плавать fOffset);
/ / Переместить указатель на указанный секунд Слушать
DLLEXPORT_API Int __stdcall HH5PLAYER_SeekToSecond (USHORT NPort, Int нсек);
/ / Цикл
DLLEXPORT_API Int __stdcall HH5PLAYER_SetPlayLoop (USHORT NPort, BOOL bIsLoop);
/ / До игры статус сообщения (1.H5PLAYER_MSG_PLAY_END: ??Воспроизведение файлов конце 2 прогресса воспроизведения:. 0 Файл с длиной <)
DLLEXPORT_API Int __stdcall HH5PLAYER_RegPlayStatusMsg (USHORT NPort, HWND HWND, UINT MessageID);


//------------------------------ 3, ход игры -------------- --------------------//
/ / Открытие потокового
DLLEXPORT_API Int __stdcall HH5PLAYER_OpenStream (USHORT NPort);
/ / Видеовход
DLLEXPORT_API Int __stdcall HH5PLAYER_PutDecStreamData (USHORT NPort, PByte pBuf, DWORD nSize, Int nDataType);
/ / Ввод расширенных видео
DLLEXPORT_API Int __stdcall HH5PLAYER_PutDecStreamDataEx (USHORT NPort, PByte pBuf, DWORD nSize, UINT nDataType, HH5KAV_INFO * pAVInfo);
/ / Стоп видео
DLLEXPORT_API Int __stdcall HH5PLAYER_StopStream (USHORT NPort);
/ / Закрыть видео
DLLEXPORT_API Int __stdcall HH5PLAYER_CloseStream (USHORT NPort);
/ / Получить размер кадра
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamFrameSize (USHORT NPort);
/ / Получить аудио размер кадра
DLLEXPORT_API Int __stdcall HH5PLAYER_GetAudioFrameSize (USHORT NPort);
/ / Установить скорость воспроизведения
DLLEXPORT_API Int __stdcall HH5PLAYER_SetStreamPlaySpeed ??(USHORT NPort, USHORT nSpeed);
/ / Получить скорость воспроизведения
DLLEXPORT_API Int __stdcall HH5PLAYER_GetStreamPlaySpeed ??(USHORT NPort);
/ / Установить скорость воспроизведения 2, FValue: время игры в кадре, такие как: 40 мс, 33.3ms, bDelayAdjust: является ли Есть выпадения кадров, калибровки времени (Примечание: Если ключевые кадры из игры, должен быть установлен в FALSE)
DLLEXPORT_API Int HH5PLAYER_SetStreamPlaySpeed2 __stdcall (USHORT NPort, плавать FValue, BOOL bDelayAdjust = TRUE);

//------------------------------ 4, прочие операционные игроков ------------- ---------------------//
/ / Установить аудио
DLLEXPORT_API Int __stdcall HH5PLAYER_SetAudio (USHORT NPort, BOOL bEnabled);
/ / Обновить изображение
DLLEXPORT_API Int __stdcall HH5PLAYER_UpDateImage (USHORT NPort);
/ / Обновить границ дисплее
DLLEXPORT_API Int __stdcall HH5PLAYER_UpdateBounds (USHORT NPort);
/ / Установить дисплее
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayhWnd (USHORT NPort, HWND HWND);
/ / Местные Увеличить
DLLEXPORT_API Int __stdcall HH5PLAYER_SetPartDisplay (USHORT NPort, HWND hPartWnd, RECT * pPartRect);
/ / Захват текущего изображения
DLLEXPORT_API Int __stdcall HH5PLAYER_CaptureOnePicture (USHORT NPort, недействительным ** bmpbuf, Int & bmpsize);
/ / Получить объем
DLLEXPORT_API Int __stdcall HH5PLAYER_GetVolume (USHORT NPort, долго lpVolume *);
/ / Установить объем
DLLEXPORT_API Int __stdcall HH5PLAYER_SetVolume (USHORT NPort, долго lVolume);
/ / Показать настройки качества 0: высокая 1: низкое качество
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDecoderQulity (BOOL bQulity);
/ / Display Control bZoomIn: большой экран, bDeInterlace: Потребители чересстрочной зигзаг, bPlayMode TRUE FALSE гладкой приоритет реального времени приоритет
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDecoderParam (BOOL bZoomIn, BOOL bDeInterlace, BOOL bPlayMode = FALSE);
/ / Когда беглости во-первых, кэшированных кадров (1 к 60)
DLLEXPORT_API Int __stdcall HH5PLAYER_SetVideoBufferSize (INT nFrameNum = 15);
/ / Очищаем все кэш
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearAllBuffer (USHORT NPort);
/ / Очистить видеобуфера
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearVideoBuffer (USHORT NPort);
/ / Очистить аудио буфера
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearAudioBuffer (USHORT NPort);
/ / Очищаем поверхность DirctX
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearImage (USHORT NPort, DWORD dwColor = 0);


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
DLLEXPORT_API Int __stdcall HH5PLAYER_SelectH264 (USHORT NPort, UINT nVersion);
/ / Anti-разрушения переключатель ложной: от истинного: открытый
DLLEXPORT_API Int __stdcall HH5PLAYER_WaitForVerticalBlank (BOOL bWait = False);

/ / Примечание: Если вы хотите наложить изображения на видео изображение, рисовать линии, и т.д., пожалуйста, используйте следующие функции инициализации плеера, и bSupportDraw значение "истина" (в окно проигрывателя для поддержки внешних или внутренних HDC)
/ / Инициализация Play 2
DLLEXPORT_API Int HH5PLAYER_InitPlayer2 __stdcall (USHORT NPort, HWND HWND, BOOL bSupportDraw = False);
/ / Воспроизвести краски
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawImage (USHORT NPort, Int х, у Int, неподписанные символ pBmpImage *, Int nSize);
/ / Воспроизвести текста OSD
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawText (USHORT NPort, Int х, у Int, символ pszText *, LOGFONT футов, COLORREF crText, COLORREF crBack = -1 / * crBack -1: прозрачный * /);
/ / Установить щетки
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDrawPen (USHORT NPort, Int nPenStyle, Int nWidth, COLORREF crColor);
/ / Рисуем линию
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawLine (USHORT NPort, Int x1, y1 Int, Int x2, y2 Int);
/ / Frame
DLLEXPORT_API Int __stdcall HH5PLAYER_DrawRect (USHORT NPort, Int x1, y1 Int, Int x2, y2 Int);
/ / Очистить дисплей
DLLEXPORT_API Int __stdcall HH5PLAYER_ClearDraw (USHORT NPort, Int nType); / / nType: 0 все, 1 изображение, 2 текста, 3 линия, прямоугольник

ЬурейеЕ Int (WINAPI * HHCBOnDraw) (USHORT NPort, HDC HDC, Int nWidth, Int nHeight, pContext недействительными *); / / HDC поддержка для внешних вызовов
DLLEXPORT_API Int __stdcall HH5PLAYER_RegCBOnDraw (USHORT NPort, HHCBOnDraw pCBOnDraw, недействительным * pContext = NULL);

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
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayGUIDEx (USHORT NPort, символ pGuid *);
DLLEXPORT_API Int __stdcall HH5PLAYER_SetDisplayWndEx (USHORT NPort, неподписанные nFirstScreenWidth Int);

ЬурейеЕ Int (WINAPI * YUVDataCallBack) (USHORT NPort,
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

ЬурейеЕ Int (WINAPI * DrawImageCallBack) (USHORT NPort,
HDC HDC,
неподписанные символ pDispBuf *,
неподписанных Int nStride,
неподписанных nDDrawMode Int
);
DLLEXPORT_API Int __stdcall HH5PLAYER_RegDrawImageCallBack (DrawImageCallBack pDrawImageCallBack);


# Endif

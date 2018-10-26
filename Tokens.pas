unit Tokens;

interface

uses
  Windows, SysUtils, Graphics, Variants, ExtCtrls, StdCtrls, ComCtrls,
  Classes, Controls, Contnrs, StrUtils, RichEdit;

type
  TTokenList = class(TList)
    S : string;
  end;
  TTxtColor = (tcText, tcComment, tcAsm, tcLiteral, tcKeyWord, ttIdentifier, ttPreproc, tcNumber, tcDiff);
  PTxtDef = ^TTxtDef;
  TTxtDef = record
    Color : TColor;
    Bold  : boolean;
    Italic: boolean;
  end;
  PTxtDefs = ^TTxtDefs;
  TTxtDefs = array [TTxtColor ] of TTxtDef;
  TTokenType = (ttKeyWord, ttWord, ttLiteral, ttNumber, ttSeparator, ttCmtStart, ttCmtEnd, ttEOL, ttBlank, ttEnd);
  TTokenSet = set of TTokenType;
  PToken = ^TToken;
  TToken = record
    TokenType : TTokenType;
    iKeyWord  : integer;
    Token   : string;
    Comment : boolean;
    LineCmt : boolean;
    AsmBody : boolean;
    Def   : TTxtColor;
    Len   : integer;
    Pos   : integer;
    Size  : integer;
  end;
  TLang = class(TObject)
  public
    FilesName : string;
    FontFace  : string;
    FontSize: integer;
    Color   : TColor;
    CharSet : Byte;
    CaseSensitive : boolean;
    TxtDefs : TTxtDefs;
    ExtList : string;
    KeyWords: string;
    InComm, LineComm : boolean;
  function  NextToken(var P : PChar): PToken;
  procedure TokenList(L : TTokenList);
  procedure CheckKeys(L : TTokenList);
  procedure Save;
  procedure LoadFromStream(S : TStream);
  procedure Activate; virtual;
  procedure Assign(Source: TLang);
  function  HasExt(Ext : string) : boolean;
  function  PostParse(var P : PChar; Token : PToken) : boolean; virtual;
  function  PredParse(var P : PChar; Token : PToken) : boolean; virtual;
  function  KeyWordInd(const word: string): integer;
  constructor Create;
  procedure  StdInit; virtual;
  end;

  TPascal = class(TLang)
    function  PredParse(var P : PChar; Token : PToken) : boolean; override;
    procedure StdInit; override;
    procedure Activate;override;
  end;
  TCPP   = class(TPascal)
    function  PredParse(var P : PChar; Token : PToken) : boolean; override;
    procedure StdInit; override;
  end;
  THtml  = class(TLang)
    function  PredParse(var P : PChar; Token : PToken) : boolean; override;
    procedure StdInit; override;
  end;
  TSQL  = class(TLang)
    function  PredParse(var P : PChar; Token : PToken) : boolean; override;
    procedure StdInit; override;
  end;
  TBat  = class(TLang)
    function  PredParse(var P : PChar; Token : PToken) : boolean; override;
    procedure StdInit; override;
  end;
  TText  = class(TLang)
    function  PredParse(var P : PChar; Token : PToken) : boolean; override;
    procedure StdInit; override;
  end;

  procedure MakeList(var S : string; const V : string);
  function  CompareKeys(P1, P2: Pointer; Length: Integer): integer; assembler;
  procedure ClearTokenList(L : TTokenList);
  procedure FreeTokenList(L : TTokenList);
  procedure SetSelectColor(Source : TCustomRichEdit; var iPos : integer; Len : integer; Def : TTxtColor);
  procedure SetColors(Source : TCustomRichEdit; var iPos : integer; SL : TTokenList; I1, I2 : integer);
  function  FileExt(FileName : string) : string;
  function  FindLang(const Ext : string) : boolean;
  function  ExtInList(const Ext, S : string) : boolean;

  var
    TokenNames : array[ TTokenType ] of string = ('KeyWord', 'Word', 'Literal', 'Number',
      'Separator', 'CommentStart', 'CommentEnd', 'EOL', 'Blank', 'End');

    Lang : TLang = nil;
    StdDefs : TTxtDefs = ((Color:clWhite;Bold:False;Italic:False),
             (Color:clGray;Bold:False;Italic:False),
             (Color:clGreen;Bold:False;Italic:False),
             (Color:clYellow;Bold:False;Italic:False),
             (Color:clAqua;Bold:False;Italic:False),
             (Color:clWhite;Bold:False;Italic:False),
             (Color:clWhite;Bold:False;Italic:False),
             (Color:clPurple;Bold:False;Italic:False),
             (Color:clRed;Bold:False;Italic:False));

    Langs : TObjectList;
    iAsm  : integer = 9;
    iEnd  : integer = 11;

implementation

function CompareKeys(P1, P2: Pointer; Length: Integer): integer; assembler;
asm
        PUSH    ESI
        PUSH    EDI
        MOV     ESI,P1
        MOV     EDI,P2
        XOR     EAX,EAX
        REPE    CMPSB
        JE      @@2
        JG      @@1
        NOT     EAX
        JMP     @@2
@@1:    INC     EAX
@@2:    POP     EDI
        POP     ESI
end;

function PosEx(sub, s : string; ipos : integer) : integer;
var B, E : PChar;
begin
  B := PChar(s);
  E := StrPos(B + ipos - 1, PChar(sub));
  if E = nil then
    Result := 0
  else
    Result := E - B + 1;
end;

function ExtInList(const Ext, S : string) : boolean;
var LW, I, J : integer;
begin
  Result := True;
  I := 1;
  repeat
    J := PosEx(',', S, I);
    if J = 0 then
      LW := Length(S) - I + 1
    else
      LW := J - I;
    if Copy(S, I, LW) = Ext then
      Exit;
    I := J + 1;
  until J = 0;
  Result := False;
end;

function FileExt(FileName : string) : string;
begin
  Result := LowerCase(ExtractFileExt(FileName));
  if Result = '' then
    Result := 'txt'
  else
    Delete(Result, 1, 1);
end;

function FindLang(const Ext : string) : boolean;
var L : integer;
begin
  Result := True;
  if (Lang <> nil) and Lang.HasExt(Ext) then
    Exit;
  for L := 0 to Langs.Count - 1 do
    if TLang(Langs[ L ]).HasExt(Ext) then
    begin
      Lang := TLang(Langs[ L ]);
      Exit;
    end;
  Result := False;
end;

procedure SetSelectColor(Source : TCustomRichEdit; var iPos : integer; Len : integer; Def : TTxtColor);
var
  CharRange : TCharRange;
  Format : TCharFormat;
begin
  CharRange.cpMin := iPos;
  CharRange.cpMax := iPos + Len;
  SendMessage(Source.Handle, EM_EXSETSEL, 0, Longint(@CharRange));
  FillChar(Format, SizeOf(TCharFormat), 0);
  Format.cbSize := SizeOf(TCharFormat);
  with Format, Lang, TxtDefs[ Def ] do
  begin
    dwMask   := Integer(CFM_COLOR or CFM_FACE or CFM_SIZE or CFM_BOLD or CFM_ITALIC or  CFM_CHARSET);
    StrPLCopy(szFaceName, FontFace, SizeOf(szFaceName) - 1);
    yHeight  := FontSize * 20;
    bCharSet := Charset;
    if Color = clWindowText then
      dwEffects := CFE_AUTOCOLOR else
      crTextColor := ColorToRGB(Color);
    if Bold then
      dwEffects := dwEffects or CFE_BOLD;
    if Italic then
      dwEffects := dwEffects or CFE_ITALIC;
  end;
  SendMessage(Source.Handle, EM_SETCHARFORMAT, SCF_SELECTION, LPARAM(@Format));
  Inc(iPos, Len);
end;

procedure SetColors(Source : TCustomRichEdit; var iPos : integer; SL : TTokenList; I1, I2 : integer);
var N : integer;
    Len : integer;
    Def : TTxtColor;
begin
  N := I1;
  while N < I2 do
  begin
    Def := PToken(SL[ N ])^.Def;
    Len := 0;
    while (N < I2) and (PToken(SL[ N ])^.Def = Def) do
    begin
      Inc(Len, PToken(SL[ N ]).Size);
      Inc(N);
    end;
    SetSelectColor(Source, iPos, Len, Def);
  end;
end;

function TLang.NextToken(var P : PChar): PToken;
var Start : PChar;
begin
  New(Result);
  FillChar(Result^, SizeOf(TToken), #0);
  Start := P;
  with Result^ do
  begin
    if not PredParse(P, Result) then
    case P^ of
     #1..#32 :
       begin
         TokenType := ttBlank;
         while P^ in [#1..#32] do
         begin
           if P^ in [#10, #13] then
           begin
             Inc(P);
             if P^ in [#10, #13] then
               Inc(P);
             TokenType := ttEOL;
             Break;
           end;
           Inc(P);
         end;
       end;
     #0 :
       begin
         TokenType := ttEnd;
         Size := 0;
       end;
     '0'..'9' :
       begin
         Inc(P);
         while P^ in ['0'..'9'] do Inc(P);
         if P^ = '.' then
         begin
           Inc(P);
           while P^ in ['0'..'9'] do Inc(P);
         end;
         if UpperCase(P^) = 'E' then
         begin
           if P^ in ['-', '+'] then
             Inc(P);
           while P^ in ['0'..'9'] do Inc(P);
         end;
         TokenType := ttNumber;
       end;
     'A'..'Z', 'a'..'z', '_' :
       begin
         while P^ in ['A'..'Z', 'a'..'z', '0'..'9', '_'] do Inc(P);
         TokenType := ttWord;
       end;
    else
      if not PostParse(P, Result) then
      begin
        TokenType := ttSeparator;
        Inc(P);
      end;
    end;
    Len := P - Start;
    SetString(Token, Start, Len);
    if TokenType in [ttWord, ttNumber] then
    begin
      if CaseSensitive or (TokenType = ttNumber) then
        Token := LowerCase(Token);
      if (TokenType = ttWord) then
      begin
        if not CaseSensitive then
          Token := LowerCase(Token);
        iKeyWord := KeyWordInd(Token);
        if iKeyWord <> -1 then
          TokenType := ttKeyWord;
      end;
    end;
  end;
end;

procedure ClearTokenList(L : TTokenList);
var I : integer;
begin
  for I := 0 to L.Count - 1 do
    Dispose(L[ I ]);
  L.Clear;
end;

procedure FreeTokenList(L : TTokenList);
begin
  ClearTokenList(L);
  L.Free;
end;

procedure TLang.CheckKeys(L : TTokenList);
var I : integer;
begin
  for I := 0 to L.Count - 1 do with PToken(L[ I ])^ do
    if TokenType in [ttWord, ttKeyWord] then
    begin
      iKeyWord := KeyWordInd(Token);
      if iKeyWord = -1 then
        TokenType  := ttWord
      else
        TokenType  := ttKeyWord;
    end;
end;


//{$DEFINE DUMP}
procedure TLang.TokenList(L : TTokenList);
var Token, Prev : PToken;
    P : PChar;
    nPos  : integer;
    LastTok, bAsm : boolean;
    I : integer;
{$IFDEF DUMP}
    F : Text;
{$ENDIF}
begin
  InComm := False;
  LineComm := False;
  Prev := nil;
  nPos := 0;
  ClearTokenList(L);
  P := PChar(L.S);
  repeat
    Token  := NextToken(P);
    Token^.Pos := nPos;
    Inc(nPos, Token.Len);

    if Token.TokenType = ttCmtStart then
    begin
      InComm := True;
      LineComm := Token.LineCmt;
    end;
    Token.Comment := InComm;
    if Token.TokenType = ttCmtEnd then
    begin
      InComm := False;
      LineComm := False;
    end;
    if Token.TokenType in [ttEOL..ttEnd] then
    begin
      if (Token.TokenType = ttEOL) and LineComm and InComm then
      begin
        InComm := False;
        LineComm := False;
      end;
      LastTok := Token.TokenType = ttEnd;
      if LastTok and (Prev <> nil) then
        Prev.Size := Token.Pos - Prev.Pos;
      Dispose(Token);
      if LastTok then
        Break;
    end else
    begin
      if Prev <> nil then
        Prev.Size := Token.Pos - Prev.Pos;
      L.Add(Token);
      Prev := Token;
    end;
  until False;
  bAsm := False;
  for I := 0 to L.Count - 1 do with PToken(L[ I ])^ do
  begin
    if Comment then
      Def := tcComment
    else if bAsm then
    begin
      if (TokenType = ttKeyWord) and (iKeyWord = iEnd) then
      begin
        Def := tcKeyWord;
        bAsm := False;
      end else
      begin
        Def := tcAsm;
        AsmBody := True;
      end;
    end else case TokenType of
      ttLiteral :
        Def := tcLiteral;
      ttSeparator :
        Def := tcKeyWord;
      ttWord :
        Def := tcText;
      ttKeyWord :
        begin
          Def := tcKeyWord;
          if iKeyWord = iAsm then
            bAsm := True;
        end;
      ttNumber  :
        Def := tcNumber;
    else
      Def := tcText;
    end;
  end;
{$IFDEF DUMP}
  AssignFile(F, 'c:\dump.txt');
  Rewrite(F);
  for I := 0 to L.Count - 1 do with PToken(L[ I ])^ do
    Write(F, Copy(L.S, Pos + 1, Size));
  CloseFile(F);
{$ENDIF}
end;

{ TPascal }

procedure TLang.LoadFromStream(S : TStream);
var L   : Byte;
    Len : integer;
begin
  S.Read(L, Sizeof(Byte));
  SetLength(FontFace, L);
  S.Read(FontFace[ 1 ], L);
  S.Read(CharSet, SizeOf(Byte));
  S.Read(FontSize, SizeOf(integer));
  S.Read(Color, SizeOf(TColor));
  S.Read(CaseSensitive, SizeOf(boolean));
  S.Read(TxtDefs, SizeOf(TTxtDefs));
  S.Read(Len, Sizeof(Integer));
  SetLength(ExtList, Len);
  S.Read(ExtList[ 1 ], Len);
  S.Read(Len, Sizeof(Integer));
  SetLength(KeyWords, Len);
  S.Read(KeyWords[ 1 ], Len);
end;

constructor TLang.Create;
//var S : THandleStream;
//    H : integer;
begin
  inherited Create;
  FilesName := Copy(ClassName, 2, MaxInt);
{  H := FileOpen(FilesName + '.ldf', fmOpenRead);
  if H <> -1 then
  begin
    S := THandleStream.Create(H);
    try
      LoadFromStream(S);
    finally
      S.Free;
      CloseHandle(H);
    end;
  end
  else}
    StdInit;
  Langs.Add(Self);
end;

procedure TLang.Save;
var L : Byte;
    S : TFileStream;
    Len : integer;
begin
  S := TFileStream.Create(FilesName + '.ldf', fmCreate);
  try
    L := Length(FontFace);
    S.Write(L, Sizeof(Byte));
    S.Write(FontFace[ 1 ], L);
    S.Write(CharSet, SizeOf(Byte));
    S.Write(FontSize, SizeOf(integer));
    S.Write(Color, SizeOf(TColor));
    S.Write(CaseSensitive, SizeOf(boolean));
    S.Write(TxtDefs, SizeOf(TTxtDefs));
    Len := Length(ExtList);
    S.Write(Len, Sizeof(Integer));
    S.Write(ExtList[ 1 ], Len);
    Len := Length(KeyWords);
    S.Write(Len, Sizeof(Integer));
    S.Write(KeyWords[ 1 ], Len);
  finally
    S.Free;
  end;
end;

procedure MakeList(var S : string; const V : string);
var I, J, LW, Len : integer;
begin
  if V = '' then
  begin
    S := '';
    Exit;
  end;
  S := ',' + V;
  Len := Length(S);
  I := 1;
  repeat
    J := PosEx(',', S, I + 1);
    if J = 0 then
      LW := Len - I
    else
      LW := J - I - 1;
    S[ I ] := Chr(LW);
    I := J;
  until J = 0;
end;

procedure TLang.StdInit;
begin
  FontFace  := 'Courier New';
  CharSet   := DEFAULT_CHARSET;
  FontSize  := 12;
  CaseSensitive := False;
  Color     := clBlack;
  TxtDefs   := StdDefs;
end;

procedure TPascal.StdInit;
begin
  inherited;
  MakeList(ExtList, 'pas,~pas,dpr,~dpr,inc,~inc,lpr,~lpr');
  MakeList(KeyWords, 'as,do,if,in,is,of,or,to,and,asm,'
    +'div,end,for,mod,nil,not,out,set,shl,shr,try,var,'
    +'xor,case,else,file,goto,then,type,unit,uses,'
    +'with,array,begin,class,const,label,raise,'
    +'until,while,downto,except,inline,object,'
    +'packed,record,repeat,string,exports,finally,'
    +'library,program,function,property,inherited,'
    +'interface,procedure,threadvar,destructor,constructor,'
    +'finalization,dispinterface,implementation,initialization,resourcestring');
end;

function TLang.KeyWordInd(const word: string): integer;
var PK : PChar;
    I, L, Len : integer;
begin
  Result := -1;
  PK := PChar(KeyWords);
  L := Ord(PK^);
  if L = 0 then
    Exit;
  Len := Length(word);
  I  := 0;
  Inc(PK);
  while L <> 0 do
  begin
    if L >= Len then
      Break;
    Inc(PK, L);
    L := Ord(PK^);
    Inc(PK);
    Inc(I);
  end;
  while L = Len do
  begin
    case CompareKeys(PK, @word[ 1 ], L) of
    0 :
      begin
        Result  := I;
        Exit;
      end;
    1 : Exit;
    end;
    Inc(PK, L);
    L := Ord(PK^);
    Inc(PK);
    Inc(I);
  end;
end;

function TLang.HasExt(Ext: string): boolean;
var P : PChar;
    L : integer;
begin
  Result := True;
  P := PChar(ExtList);
  L := Ord(P^);
  Inc(P);
  while L <> 0 do
  begin
    if (L = Length(Ext)) and (CompareKeys(P, @Ext[ 1 ], L) = 0) then
      Exit;
    Inc(P, L);
    L := Ord(P^);
    Inc(P);
  end;
  Result := False;
end;

procedure TLang.Activate;
begin
end;

procedure TPascal.Activate;
begin
  iAsm := KeyWordInd('asm');
  iEnd := KeyWordInd('end');
end;

procedure TLang.Assign(Source: TLang);
begin
  if Source = nil then
    Exit;
  FilesName := Source.FilesName;
  FontFace := Source.FontFace;
  FontSize := Source.FontSize;
  Color :=  Source.Color;
  CharSet := Source.CharSet;
  CaseSensitive := Source.CaseSensitive;
  TxtDefs  := Source.TxtDefs;
  ExtList  := Source.ExtList;
  KeyWords := Source.KeyWords;
end;

function TPascal.PredParse(var P: PChar; Token: PToken): boolean;
var Hex : boolean;
begin
  with Token^ do
  case P^ of
   '(' :
     begin
       Inc(P);
       TokenType := ttSeparator;
       if (P^ = '*') and not InComm then
       begin
         Inc(P);
         TokenType := ttCmtStart;
       end;
     end;
   '*' :
     begin
       Inc(P);
       TokenType := ttSeparator;
       if P^ = ')' then
       begin
         Inc(P);
         TokenType := ttCmtEnd;
       end;
     end;
   '}' :
     begin
       Inc(P);
       TokenType := ttCmtEnd;
     end;
   '''':
     begin
       if InComm or LineComm then
       begin
         Inc(P);
         TokenType := ttSeparator;
       end else
       begin
         AnsiExtractQuotedStr(P, P^);
         TokenType := ttLiteral;
       end;
     end;
   '{' :
     begin
       Inc(P);
       if not InComm  then
         TokenType := ttCmtStart
       else
         TokenType := ttSeparator;
     end;
     '/' :
     begin
       Inc(P);
       TokenType := ttSeparator;
       if (P^ = '/') and not InComm then
       begin
         Inc(P);
         TokenType := ttCmtStart;
         LineCmt := True;
       end;
     end;
   '#', '$' :
     begin
       if P^ = '#' then
       begin
         Inc(P);
         Hex := P^ = '$';
         if Hex or (P^ in ['0'..'9']) then
           TokenType := ttLiteral
         else
           TokenType := ttSeparator
       end else
       begin
         Hex := True;
         TokenType := ttNumber;
         Inc(P);
       end;
       while (P^ in ['0'..'9']) or Hex and (P^ in ['a'..'f', 'A'..'F']) do Inc(P);
     end;
   end;
  Result := Token.TokenType <> ttKeyWord;
end;

{ TCPP }

function TCPP.PredParse(var P: PChar; Token: PToken): boolean;
begin
  with Token^ do
  case P^ of
   '/' :
     begin
       Inc(P);
       TokenType := ttSeparator;
       if (P^ = '*') and not InComm then
       begin
         Inc(P);
         TokenType := ttCmtStart;
       end else if (P^ = '/') and not InComm then
       begin
         Inc(P);
         TokenType := ttCmtStart;
         LineCmt := True;
       end;
     end;
   '*' :
     begin
       Inc(P);
       TokenType := ttSeparator;
       if P^ = '/' then
       begin
         Inc(P);
         TokenType := ttCmtEnd;
       end;
     end;
   '"','''':
     begin
       AnsiExtractQuotedStr(P, P^);
       TokenType := ttLiteral;
     end;
   '0' :
     begin
       if (P + 1)^ in ['x','X'] then
       begin
         TokenType := ttNumber;
         Inc(P, 2);
         while P^ in ['0'..'9', 'a'..'f', 'A'..'F'] do Inc(P);
       end;
     end;
   end;
  Result := Token.TokenType <> ttKeyWord;
end;

procedure TCPP.StdInit;
begin
  inherited;
  MakeList(ExtList, 'cpp,~cpp,c,~c,h,~h');
  MakeList(KeyWords, 'do,if,asm,for,int,new,bool,case,char,else,enum,goto,long,this,true,void,array,'
  +'based,break,catch,cdecl,class,const,event,false,float,naked,short,throw,union,while,'
  +'assume,delete,double,extern,friend,inline,public,return,sealed,signed,sizeof,'
  +'static,struct,switch,thread,typeid,alignof,default,finally,generic,literal,'
  +'mutable,private,typedef,abstract,continue,delegate,explicit,initonly,noinline,property,'
  +'register,template,typename,unsigned,volatile,dllexport,dllimport,interface,namespace,protected,deprecated');
end;

{ THtml }

function THtml.PredParse(var P: PChar; Token: PToken): boolean;
begin
  with Token^ do
  if AnsiStrLIComp(P, '<!--', 4) = 0 then
  begin
    Inc(P, 4);
    TokenType := ttCmtStart;
  end else if AnsiStrLIComp(P, '-->', 3) = 0 then
  begin
    Inc(P, 3);
    TokenType := ttCmtEnd;
  end else
  case P^ of
   '"':
     begin
       AnsiExtractQuotedStr(P, P^);
       TokenType := ttLiteral;
     end;
  end;
  Result := Token.TokenType <> ttKeyWord;
end;

procedure THtml.StdInit;
begin
  inherited;
  MakeList(ExtList, 'htm,~htm,html,~html');
  MakeList(KeyWords, 'a,b,i,p,q,s,u,br,dd,dl,dt,em,h1,h2,h3,h4,h5,h6,hr,li,'
  +'ol,td,th,tr,tt,ul,bdo,big,col,del,dfn,dir,div,img,ins,kbd,map,'
  +'pre,sub,sup,var,xmp,abbr,area,base,body,cite,code,font,form,head,html,link,menu,meta,'
  +'nobr,samp,span,blink,embed,frame,input,label,param,small,style,table,tbody,tfoot,'
  +'title,applet,button,center,iframe,legend,object,option,script,select,strike,'
  +'strong,acronym,address,bgsound,caption,comment,isindex,marquee,noembed,basefont,colgroup,'
  +'fieldset,frameset,noframes,noscript,optgroup,textarea,plaintext,blockquote');
end;

{ TSQL }

function TSQL.PredParse(var P: PChar; Token: PToken): boolean;
begin
 with Token^ do
  case P^ of
   '/' :
     begin
       Inc(P);
       TokenType := ttSeparator;
       if (P^ = '*') and not InComm then
       begin
         Inc(P);
         TokenType := ttCmtStart;
       end else if (P^ = '/') and not InComm then
       begin
         Inc(P);
         TokenType := ttCmtStart;
         LineCmt := True;
       end;
     end;
   '*' :
     begin
       Inc(P);
       TokenType := ttSeparator;
       if P^ = '/' then
       begin
         Inc(P);
         TokenType := ttCmtEnd;
       end;
     end;
   '#' :
     begin
       Inc(P);
       if not InComm then
       begin
         TokenType := ttCmtStart;
         LineCmt := True;
       end else
         TokenType := ttSeparator;
     end;
   '"':
     begin
       AnsiExtractQuotedStr(P, P^);
       TokenType := ttLiteral;
     end;
   end;
  Result := Token.TokenType <> ttKeyWord;
end;

procedure TSQL.StdInit;
begin
  inherited;
  MakeList(ExtList, 'sql,~sql');
  MakeList(KeyWords, 'as,at,by,go,in,is,no,of,on,or,to,add,all,and,any,are,asc,avg,bit,day,dec,end,for,get,int,key,max,min,not,pad,set,sql,sum,both,case,cast,char,'
+'date,desc,drop,else,exec,from,full,goto,hour,into,join,last,left,like,next,null,'
+'only,open,read,real,rows,size,some,then,time,trim,true,user,view,when,'
+'with,work,year,zone,alter,begin,check,close,cross,false,fetch,first,float,found,grant,group,inner,'
+'input,level,local,lower,match,month,names,nchar,order,outer,prior,right,space,'
+'table,union,upper,usage,using,value,where,write,action,column,commit,create,cursor,delete,domain,'
+'double,escape,except,exists,global,having,insert,minute,module,nullif,'
+'option,output,public,revoke,schema,scroll,second,select,unique,update,values,between,cascade,catalog,'
+'collate,connect,convert,current,decimal,declare,default,endexec,execute,extract,foreign,integer,leading,'
+'natural,numeric,partial,prepare,primary,section,session,sqlcode,unknown,varchar,varying,absolute,allocate,'
+'cascaded,coalesce,continue,deferred,describe,distinct,external,identity,interval,language,national,overlaps,'
+'position,preserve,relative,restrict,rollback,smallint,sqlerror,'
+'sqlstate,trailing,whenever,assertion,character,collation,exception,immediate,indicator,initially,'
+'intersect,isolation,precision,procedure,substring,temporary,timestamp,translate,bit_length,connection,'
+'constraint,deallocate,deferrable,descriptor,disconnect,privileges,references,char_length,constraints,diagnostics,'
+'insensitive,system_user,transaction,translation,current_date,current_time,current_user,octet_length,'
+'session_user,authorization,corresponding,timezone_hour,timezone_minute,character_length,current_timestamp');
end;

{ TBat }

function TBat.PredParse(var P: PChar; Token: PToken): boolean;
begin
  if AnsiStrLIComp(P, 'rem', 3) = 0 then with Token^ do
  begin
    Inc(P, 3);
    TokenType := ttCmtStart;
    LineCmt := True;
  end else
  case P^ of
  '"', '''' :
    begin
      AnsiExtractQuotedStr(P, P^);
      Token.TokenType := ttLiteral;
    end;
  end;
  Result := Token.TokenType <> ttKeyWord;
end;

procedure TBat.StdInit;
begin
  inherited;
  MakeList(ExtList, 'bat,~bat');
  MakeList(KeyWords, 'at,cd,fc,if,md,rd,cls,cmd,'
   +'del,dir,for,rem,ren,set,ver,vol,call,chcp,comp,copy,date,echo,exit,find,'
   +'goto,help,mode,more,move,path,popd,sort,time,tree,type,assoc,break,cacls,'
   +'chdir,color,erase,ftype,label,mkdir,pause,print,pushd,rmdir,shift,start,subst,'
   +'title,xcopy,attrib,chkdsk,doskey,format,prompt,rename,verify,chkntfs,compact,'
   +'convert,findstr,recover,replace,diskcomp,diskcopy,endlocal,graftabl,setlocal');
end;

{ TText }

function TText.PredParse(var P: PChar; Token: PToken): boolean;
begin
  Result := False;
end;

procedure TText.StdInit;
begin
  inherited;
  MakeList(ExtList, 'txt,~txt');
  MakeList(KeyWords, '');
end;

function TLang.PredParse(var P: PChar; Token: PToken): boolean;
begin
  Result := False;
end;

function TLang.PostParse(var P: PChar; Token: PToken): boolean;
begin
  Result := False;
end;

initialization
  Langs := TObjectList.Create;

finalization
  Langs.Free;

end.

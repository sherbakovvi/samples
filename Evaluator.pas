unit Evaluator;

interface

uses StrUtils, SysUtils, Classes, Windows, Contnrs,
     Messages, Dialogs, Variants, DateUtils;

const
  AlphaNum = ['a'..'z', 'A'..'Z', 'а'..'€', 'ј'..'я', '_', '1'..'9', '0'];

type
  TPreCheck = procedure (List, SetList : TStringList);
  TLog      = procedure(S : string);

function  EvalExp(const S : string; PreCheck : TPreCheck; VarList, SetList : TStringList) : Variant;
procedure SetCheck(L, SetList : TStringList);

var
  eLog : TLog = nil;

implementation

// Op    |  =, <>, in, *, +, -, or, and, not
// paran |  ()[]
// sep   |  , blank

// права€ 	! ~ \ = \ унарные + и -
//          != <>

// унарные
// * / not
// + -
// < <= > >=
// = <>
// and
// or

type
  TKind = (kLeftPar, kOper, kConst);
  TOper = (oMult, oSingleAdd, oSingleSub, oAdd, oSub, oIn, oEqual, oNotEqual, oGt, oGtEq, oLt, oLtEq, oNot, oAnd, oOr);
  TDataType  = (otSet, otBool, otFloat, otDate, otStr);
  PItem = ^TItem;
  TItem = record
    Kind : TKind;
    Value: Variant;
    StrValue : string;
    Src : string;
    Oper : TOper;
    List : boolean;
    DataType : TDataType;
  end;

  PTrigStateExp = ^TTrigStateExp;
  TTrigStateExp = record
    Name   : string;
    TrigID : integer;
    State  : string;
    Expr   : string;
  end;

  TOutState = (osOn, osOff);
  TSendUnchanged = set of TOutState;
  POutStateDef = ^TOutStateDef;
  TOutStateDef = record
    Name    : string;
    OutId   : integer;
    SendUnchangedTime : TDateTime;
    Expr    : string;
    State   : TOutState;
    SendUnchanged : TSendUnchanged;
  end;

const
  SKind : array[ TKind ] of string =
    ('LeftPar', 'Oper', 'Const');
  SOper : array[ TOper ] of string =
    ('*', '+', '-', '+', '-', 'in', '=', '<>', '>', '>=', '<', '<=', 'not', 'and', 'or');

  Pri : array[ TOper ] of integer =
    (10,     11,          11,          9,    9,    8,    6,     6,         7,   7,     7,   7,     11,    4,    2);
//  (oMult, oSingleAdd, oSingleSub, oAdd, oSub, oIn, oEqual, oNotEqual, oGt, oGtEq, oLt, oLtEq, oNot, oAnd, oOr);
// унарные
// * / not
// + -
// < <= > >=
// = <>
// and
// or

procedure Error(S : string);
begin
  raise Exception.Create(S);
end;

function IndInList(const Word, List : string; Sep : string = ',') : integer;
var Pred, P : PChar;
begin
  Result := -1;
  Pred   := PChar(List);
  P      := AnsiStrPos(Pred, PChar(Sep));
  if P = nil then
  begin
    if Word = Trim(List) then
      Inc(Result)
  end else
  begin
    while P <> nil do
    begin
      Inc(Result);
      if SameStr(Word, Trim(Copy(Pred, 1, P - Pred))) then
        Exit;
      Pred := P + 1;
      P := AnsiStrPos(Pred, PChar(Sep));
    end;
    if SameStr(Word, Trim(Pred)) then
      Inc(Result)
    else
      Result := -1;
  end;
end;

function WordByInd(const List : string; Ind : integer; Sep : string = ',') : string;
var Pred, P : PChar;
    N : integer;
begin
  Result := '';
  N      := 0;
  Pred   := PChar(List);
  P      := AnsiStrPos(PChar(List), PChar(Sep));
  while (N <> Ind) and (P <> nil) do
  begin
    Inc(N);
    Pred := P + 1;
    P := AnsiStrPos(Pred, PChar(Sep));
  end;
  if N = Ind then
  begin
    if P = nil then
      P := StrEnd(Pred);
    Result := Trim(Copy(Pred, 1, P - Pred));
  end;
end;

function ListCount(const List : string; Sep : string = ',') : integer;
var P : PChar;
begin
  Result := 1;
  P := AnsiStrPos(PChar(List), PChar(Sep));
  while P <> nil do
  begin
    Inc(Result);
    P := AnsiStrPos(P + 1, PChar(Sep));
  end;
end;

procedure DeleteFromList(const Word : string; var List : string; Sep : string = ',');
var Pred, P : PChar;
    nPos  : integer;
begin
  Pred   := PChar(List);
  P      := AnsiStrPos(PChar(List), PChar(Sep));
  if P = nil then
  begin
    if SameStr(Word, Trim(List)) then
      List := ''
  end else
  begin
    while P <> nil do
    begin
      if SameStr(Word, Trim(Copy(Pred, 1, P - Pred))) then
        Break;
      Pred := P + 1;
      P := AnsiStrPos(Pred, PChar(Sep));
    end;
    if P = nil then
    begin
      P := StrEnd(Pred);
      if Word <> Trim(Copy(Pred, 1, P - Pred)) then
        Exit;
    end;
    nPos := Pred - PChar(List);
    if Pred = PChar(List)then
      Inc(nPos);
    Delete(List, nPos, P - Pred + 1);
  end;
end;

procedure SetRange(List, SetList : TStringList; var Ind : integer);
var S : string;
    I, J : integer;
    ibeg : integer;
    iend : integer;
begin
  S := List[ Ind ];
  List.Delete(Ind);
  I := Pos('..', S);
  ibeg := StrToInt(Copy(S, 2, I - 2));
  iend := StrToInt(Copy(S, I + 3, MaxInt));
  for I := 0 to SetList.Count - 1 do
  begin
    J := StrToInt(Copy(SetList.Names[ I ], 2, MaxInt));
    if (J >= ibeg) and (J <= iend) then
    begin
      List.Insert(Ind, UpperCase(SetList.ValueFromIndex[ I ]));
      Inc(Ind);
    end;
  end;
end;

procedure SetCheck(L, SetList : TStringList);
var I, J : integer;
begin
  I := 0;
  while I < L.Count do
    if Pos('..', L[ I ]) <> 0 then
      SetRange(L, SetList, I)
    else
    begin
      J := SetList.IndexOfName(L[ I ]);
      if J <> -1 then
        L[ I ] := UpperCase(SetList.ValueFromIndex[ J ]);
      Inc(I);
    end;
end;

procedure SetOperandType(Item : PItem; IsVar : boolean = False);
var F : Double;
    D : TDateTime;
begin
  Item.DataType := otStr;
  with Item ^ do
  if List then
    DataType := otSet
  else {if not IsVar then} case VarType(Value) of
    varBoolean :
      DataType := otBool;
    varSmallint..varCurrency,
    varShortInt..varInt64 :
      DataType := otFloat;
    varDate :
      DataType := otDate;
    varString :
      if not IsVar then
      begin
        if TryStrToFloat(Value, F) then
        begin
          DataType := otFloat;
          Value := F;
        end else if TryStrToDateTime(Value, D) then
        begin
          DataType := otDate;
          Value := D;
        end;
      end;
  end;
end;

function ParseExp(const S : string; Res : TList; PreCheck : TPreCheck; VarList, SetList : TStringList) : boolean;
var P, P1, B, P0 : PChar;
    Stack : TStack;
    Op, Op1 : string;
    I  : integer;
    WaitOperand : boolean;
    F : Double;
    D : TDateTime;
    Ch : Char;
    Src : string;

  procedure StackToRes;
  var Tmp : PItem;
  begin
    Tmp := PItem(Stack.Pop);
    Res.Add(Tmp);
  end;

  procedure AddOp(Op : TOper);
  var Item : PItem;
      RightAsso : boolean;

      function Unload : boolean;
      var Item : PItem;
      begin
        Item   := PItem(Stack.Peek);
        Result := (Item.Kind = kOper) and
         ((Pri[ Item.Oper ] > Pri[ Op ]) or not RightAsso
          and (Pri[ Item.Oper ] = Pri[ Op ]));
      end;

  begin
    New(Item);
    Item.Kind := kOper;
    Item.Oper := Op;
    if WaitOperand then
    begin
     if Op in [ oAdd, oSub ] then
       Item.Oper := TOper(Ord(Op) - 2)
     else if Op <> oNot then
       Error('плохое выражение');
    end;
    Item.Value := null;
    Item.List  := False;
    RightAsso  := Op in [ oSingleAdd, oSingleSub, oNotEqual ];
    while (Stack.Count > 0) and  Unload do
      StackToRes;
    Stack.Push(Item);
    WaitOperand  := True;
  end;

  procedure AddVar(Kind : TKind);
  var Item : PItem;
  begin
    New(Item);
    Item.Kind  := Kind;
    Item.Oper  := oMult;
    Item.Value := null;
    Item.List  := False;
    Res.Add(Item);
    WaitOperand  := False;
  end;

  procedure AddLeftPar;
  var Item : PItem;
  begin
    New(Item);
    Item.Kind := kLeftPar;
    Item.Oper  := oMult;
    Item.Value := null;
    Item.List  := False;
    Stack.Push(Item);
    WaitOperand  := True;
  end;

  procedure AddOperand(V : Variant; List : boolean; IsVar : boolean = False);
  var Item : PItem;
  begin
    New(Item);
    Item.Kind  := kConst;
    Item.Oper  := oMult;
    Item.Src   := Src;
    if VarIsNull(V) then
      Item.Value := Op
    else
      Item.Value := V;
    Item.StrValue := Op;
    Item.List  := List;
    SetOperandType(Item, IsVar);
    Res.Add(Item);
    WaitOperand  := False;
  end;

  function GetList(const S : string) : string;
  var L : TStringList;
      I, J : integer;
      Item : string;
      Count : integer;
  begin
    L := TStringList.Create;
    try
      L.CommaText := S;
      if @PreCheck <> nil then
        PreCheck(L, SetList)
      else if SetList <> nil then
        SetCheck(L, SetList)
      else
        for I := 0 to L.Count - 1 do
        begin
          if Pos('..', L[ I ]) <> 0 then
            Error('запрещен диапазон');
          J := VarList.IndexOfName(L[ I ]);
          if J <> -1 then
            L[ I ] := UpperCase(VarList.ValueFromIndex[ J ]);
        end;
      L.Sort;
      Count := L.Count;
      I := 0;
      while I < Count do
      begin
        Item := L[ I ];
        for J := 1 to  Length(Item) do
          if not (Item[ J ] in AlphaNum) then
            Error('ѕлохой элемент списка');
        J := I + 1;
        while (J < Count) and (L[ J ] = Item) do
        begin
          L.Delete(J);
          Dec(Count);
        end;
        Inc(I);
      end;
      Result := L.CommaText;
    finally
      L.Free;
    end;
  end;

begin
  if @eLog <> nil then
    eLog('---  ' + S);
  Stack  := TStack.Create;
  WaitOperand  := True;
  try
    P := PChar(S);
    while P^ <> #0 do
    begin
      case P^ of
        '(' :
          begin
            Inc(P);
            AddLeftPar;
          end;
        ')' :
          begin
            while (Stack.Count > 0) and (PItem(Stack.Peek).Kind <> kLeftPar) do
               StackToRes;
            if Stack.Count = 0 then
              Error('нет (');
              Dispose(PItem(Stack.Pop));
            Inc(P);
          end;
        '[' :
          begin
            Inc(P);
            B := P;
            P := StrPos(P, ']');
            if P = nil then
              Error('нет ]');
            Src := '[' + Copy(B, 1, P - B) + ']';
            Op := GetList(UpperCase(Copy(B, 1, P - B)));
            AddOperand(null, True);
            Inc(P);
          end;
        ']' :
          Error('нет ]');
        ' ' :
          while P^ = ' ' do Inc(P);
        '<' :
          begin
            Inc(P);
            if P^ = '>' then
            begin
              AddOp(oNotEqual);
              Inc(P);
            end else if P^ = '=' then
            begin
              AddOp(oLtEq);
              Inc(P);
            end else
              AddOp(oLt);
          end;
        '>' :
          begin
            Inc(P);
            if P^ = '=' then
            begin
              AddOp(oGtEq);
              Inc(P);
            end else
              AddOp(oGt);
          end;
        '*' :
          begin
            Inc(P);
            AddOp(oMult);
          end;
        '+' :
          begin
            Inc(P);
            AddOp(oAdd);
          end;
        '-' :
          begin
            Inc(P);
            AddOp(oSub);
          end;
        '=' :
          begin
            Inc(P);
            AddOp(oEqual);
          end;
        '''' :
          begin
            Src := AnsiExtractQuotedStr(P, '''');
            Op  := UpperCase(Src);
            if P^ = #0 then
              Error('нет закрывающей кавычки');
            AddOperand(null, False);
          end
      else
        B := P;
        while P^ in AlphaNum do Inc(P);
        if P = B then
          Error('только цифры, буквы)');
        Op := UpperCase(TrimRight(Copy(B, 1, P - B)));
        if Op = 'AND' then
          AddOp(oAnd)
        else if Op = 'OR' then
          AddOp(oOr)
        else if Op = 'IN' then
          AddOp(oIn)
        else if Op = 'NOT' then
          AddOp(oNot)
        else
        begin
          if P^ = ',' then
          begin
            Inc(P);
            while P^ in ['0'..'9'] do
              Inc(P);
            Op := Copy(B, 1, P - B);
            Src := Op;
            if TryStrToFloat(Op, F) then
              AddOperand(F, False)
            else
              AddOperand(null, False);
          end else if P^ in ['.', ':' ] then
          begin
            P0 := P;
            Ch := P^;
            while (P^ = Ch) or (P^ in ['0'..'9']) do
              Inc(P);
            Op := Copy(B, 1, P - B);
            if TryStrToTime(Op, D) then
            begin
              Src := Op;
              AddOperand(D, False);
            end else if TryStrToDate(Op, D) then
            begin
              if (Ch = '.') and (P^ = ' ') then
              begin
                P1  := P;
                while (P1^ in ['0'..'9', '.', ':', ' ']) do
                  Inc(P1);
                Op1 := Copy(B, 1, P1 - B);
                if TryStrToDateTime(Op1, D) then
                begin
                  Op := Op1;
                  P  := P1;
                end;
              end;
              Src := Op;
              AddOperand(D, False);
            end else
            begin
              SetLength(Op, Length(Op) - 1);
              Op := Uppercase(Op);
              Src := Op;
              P := P0;
              AddOperand(null, False);
//              Error('плохой операнд');
            end;
          end else
          begin
            Src := Op;
            I := VarList.IndexOfName(Op);
            if I <> -1  then
              Op := UpperCase(VarList.ValueFromIndex[ I ]);
            AddOperand(null, False{, I <> -1});
          end;
        end;
      end;
    end;
    while (Stack.Count > 0) and (PItem(Stack.Peek).Kind = kOper) do
      StackToRes;
    Result := Stack.Count = 0;
    if @eLog <> nil then
      for I := 0 to Res.Count - 1 do
        with PItem(Res[ I ])^ do
          if Kind = kOper then
            eLog(' ' + SOper[ Oper ])
          else
            eLog(VarToStr(Value));

  finally
    while Stack.Count > 0 do
    begin
      Dispose(PItem(Stack.Peek));
      Stack.Pop;
    end;
    Stack.Free;
  end;
end;


function EvalExp(const S : string; PreCheck : TPreCheck; VarList, SetList : TStringList) : Variant;
var I     : integer;
    Stack : TStack;
    Res   : TList;
    Op1, Op2 : Variant;
    S1, S2 : string;
    Src1, Src2 : string;
    Tp1, Tp2 : TDataType;

    procedure Bad;
    begin
       Error('плохой тип операнда : ' + Src1);
    end;

    procedure GetOps(Op : TOper);

      function CheckTp : boolean;
      begin
        Result := (Tp1 = Tp2) or
          (Tp1 = otDate) and (Tp2 = otFloat) or
          (Tp2 = otDate) and (Tp1 = otFloat);
        if not Result and ((Tp1 in [otFloat, otDate]) or (Tp2 in [otFloat, otDate])) then
        begin
          Op1 := S1;
          Op2 := S2;
          Tp1 := otStr;
          Tp2 := otStr;
          Result := True;
        end;
      end;

    begin
      if not (Op in [oNot, oSingleAdd, oSingleSub]) then
        with PItem(Stack.Pop)^ do
        begin
          case Kind of
            kLeftPar, kOper :
              Error('плохое выражение');
            kConst: Op2 := Value;
          end;
          Tp2 := DataType;
          S2  := StrValue;
          Src2  := Src;
        end;
      with PItem(Stack.Peek)^ do
      begin
        case Kind of
          kLeftPar, kOper :
             Error('плохое выражение');
          kConst: Op1 := Value;
        end;
        S1  := StrValue;
        Tp1 := DataType;
        Src1  := Src;
      end;
      case Op of
        oSingleAdd, oSingleSub:
          if Tp1 <> otFloat then
            Bad;
        oMult :
          if not (Tp1 in [otFloat, otSet]) or not CheckTp then
            Bad;
        oEqual, oNotEqual:
          if (Tp1 = otBool) or  not CheckTp then
            Bad;
        oAdd:
          if (Tp1 = otBool) or not CheckTp then
            Bad;
        oSub:
          if (Tp1 = otBool) or  not CheckTp then
            Bad;
        oIn:
          begin
            if Tp1 <> otStr then
            begin
              Op1 := S1;
              Tp1 := otStr;
            end;
            if Tp2 <> otSet then
              Bad;
          end;
        oNot:
          if Tp1 <> otBool then
            Bad;
        oAnd, oOr:
          if (Tp1 <> otBool) or not CheckTp then
            Bad;
        oGt, oGtEq, oLt, oLtEq :
          if (Tp1 in [otBool, otSet]) or not CheckTp then
            Bad;
      end;
    end;

    procedure SetRes(V : Variant);
    begin
      with PItem(Stack.Peek)^ do
      begin
        Value := V;
        Kind  := kConst;
        List  := False;
        SetOperandType(PItem(Stack.Peek), True);
      end;
    end;

    procedure MultList;
    var Res, S : string;
        I : integer;
    begin
      Res := '';
      for I := 0 to ListCount(Op1) - 1 do
      begin
        S := WordByInd(Op1, I);
        if IndInList(S, Op2) <> -1 then
        begin
          if Res = '' then
            Res := S
          else
            Res := Res + ',' + S;
        end;
      end;
      SetRes(Res);
    end;

    procedure AddList;
    var Res, S : string;
        I : integer;
    begin
      Res := Op2;
      for I := 0 to ListCount(Op1) - 1 do
      begin
        S := WordByInd(Op1, I);
        if IndInList(S, Op2) = -1 then
        begin
          if Res = '' then
            Res := S
          else
            Res := Res + ',' + S;
        end;
      end;
      SetRes(Res);
    end;

    procedure SubtractList;
    var Res, S : string;
        I : integer;
    begin
      Res := Op1;
      for I := 0 to ListCount(Op2) - 1 do
      begin
        S := WordByInd(Op2, I);
        if IndInList(S, Res) <> -1 then
          DeleteFromList(S, Res);
      end;
      SetRes(Res);
    end;

    procedure InList;
    begin
      SetRes(IndInList(Op1, Op2) <> -1);
    end;

begin
  if S = '' then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
  Stack  := TStack.Create;
  try
    Res := TList.Create;
    try
      if ParseExp(S, Res, PreCheck, VarList, SetList) then
        for I := 0 to Res.Count - 1 do with PItem(Res[ I ])^ do
        begin
          if Kind <> kOper then
            Stack.Push(Res[ I ])
          else
          begin
            GetOps(Oper);
            case Oper of
             oSingleAdd  :
               SetRes(-Op1);
             oSingleSub:
               SetRes(Op1);
             oMult :
               case Tp1 of
                 otSet  :
                   MultList;
                 otFloat:
                   SetRes(Op1 * Op2);
               end;
             oAdd  :
               case Tp1 of
                 otSet  :
                   AddList;
                 otDate :
                   SetRes(TDateTime(Op1 + Op2));
                 else
                   SetRes(Op1 + Op2);
               end;
             oSub:
               case Tp1 of
                 otSet  :
                   SubtractList;
                 otDate :
                   begin
                     if Tp2 = otDate then
                       SetRes(Op1 - Op2)
                     else
                       SetRes(TDateTime(Op1 - Op2));
                   end;
                 else
                   SetRes(Op1 - Op2);
               end;
             oIn   :
               InList;
             oEqual:
               case Tp1 of
                 otDate  :
                   SetRes(CompareDateTime(Op1, Op2) = 0);
               else
                   SetRes(VarSameValue(Op1, Op2));
               end;
             oNotEqual:
               case Tp1 of
                 otDate  :
                   SetRes(CompareDateTime(Op1, Op2) <> 0);
               else
                   SetRes(not VarSameValue(Op1, Op2));
               end;
             oNot  :
               SetRes(not Op1);
             oAnd  :
               SetRes(Op1 and Op2);
             oOr   :
               SetRes(Op1 or Op2);
             oGt :
               if (Tp1 = otDate) or (Tp2 = otDate) then
                  SetRes(CompareDateTime(Op1, Op2) > 0)
               else case Tp1 of
                 otFloat : SetRes(Op1 > Op2);
                 otStr   : SetRes(CompareStr(Op1, Op2) > 0);
               end;
             oGtEq :
               if (Tp1 = otDate) or (Tp2 = otDate) then
                 SetRes(CompareDateTime(Op1, Op2) >= 0)
               else case Tp1 of
                 otFloat : SetRes(Op1 >= Op2);
                 otStr   : SetRes(CompareStr(Op1, Op2) >= 0);
               end;
             oLt :
               if (Tp1 = otDate) or (Tp2 = otDate) then
                 SetRes(CompareDateTime(Op1, Op2) < 0)
               else case Tp1 of
                 otFloat : SetRes(Op1 < Op2);
                 otStr   : SetRes(CompareStr(Op1, Op2) < 0);
               end;
             oLtEq :
               if (Tp1 = otDate) or (Tp2 = otDate) then
                 SetRes(CompareDateTime(Op1, Op2) <= 0)
               else case Tp1 of
                 otFloat : SetRes(Op1 <= Op2);
                 otStr   : SetRes(CompareStr(Op1, Op2) <= 0);
               end;
            end;
          end;
        end;
      if Stack.Count = 1 then
        Result := PItem(Stack.Peek)^.Value
      else
        Error('плохое выражение');
    finally
      for I := 0 to Res.Count - 1 do
        Dispose(PItem(Res[ I ]));
      Res.Free;
    end;
  finally
    Stack.Free;
  end;
end;

initialization

finalization

end.

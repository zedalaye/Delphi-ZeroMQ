program task_ventilator;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, zeromq;

procedure Run;
var
  Z: IZeroMQ;
  Sender: IZMQPair;
  Sink: IZMQPair;
  I, C, L: Integer;
begin
  Z := TZeroMQ.Create;
  Sender := Z.Start(ZMQ.Push);
  Sender.Bind('tcp://*:5557');
  Writeln('Started task ventilator (TCP/5557)...');

  Sink := Z.Start(ZMQ.Push);
  Sink.Connect('tcp://localhost:5558');

  Writeln('Press Enter when the workers are ready.');
  Readln;

  WriteLn('Sending tasks to workers...');

  Sink.SendString('0');
  C := 0;
  for I := 0 to 100  - 1 do
  begin
    L := Random(100) + 1;
    C := C + L;
    Sender.SendString(IntToStr(L));
  end;

  WriteLn('Total expected cost: ', C, 'ms');
  Sleep(1);
end;

begin
  try
    Randomize;
    Run;
    WriteLn;
    WriteLn('Press a key to continue...');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

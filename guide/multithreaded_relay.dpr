program multithreaded_relay;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.Classes, ZeroMQ;

type
  TWorkerThread = class(TThread)
  private
    FContext: IZeroMQ;
  public
    constructor Create(Context: IZeroMQ);
  end;

  TStep1 = class(TWorkerThread)
  protected
    procedure Execute; override;
  end;

  TStep2 = class(TWorkerThread)
  protected
    procedure Execute; override;
  end;

{ TWorkerThread }

constructor TWorkerThread.Create(Context: IZeroMQ);
begin
  inherited Create(False);
  FContext := Context;
end;

{ TStep1 }

procedure TStep1.Execute;
var
  Emitter: IZMQPair;
begin
  Emitter := FContext.Start(ZMQSocket.Pair);
  Emitter.Connect('inproc://step2');
  WriteLn('Step 1 ready, signaling step 2');
  Emitter.SendString('READY');
end;

{ TStep2 }

procedure TStep2.Execute;
var
  Receiver, Emitter: IZMQPair;
begin
  Receiver := FContext.Start(ZMQSocket.Pair);
  Receiver.Bind('inproc://step2');

  TStep1.Create(FContext);

  Receiver.ReceiveString;

  Emitter := FContext.Start(ZMQSocket.Pair);
  Emitter.Connect('inproc://step3');
  WriteLn('Step 2 ready, signaling step 3');
  Emitter.SendString('READY');
end;

procedure Run;
var
  Z: IZeroMQ;
  Receiver: IZMQPair;
begin
  Z := TZeroMQ.Create;
  Receiver := Z.Start(ZMQSocket.Pair);
  Receiver.Bind('inproc://step3');

  TStep2.Create(Z);

  Receiver.ReceiveString;

  WriteLn('Test successful!');
end;

begin
  try
    Run;
    WriteLn;
    WriteLn('Press a key to continue...');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

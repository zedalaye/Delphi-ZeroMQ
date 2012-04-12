program weather_srv;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, zeromq;

procedure Run;
var
  Z: IZeroMQ;
  P: IZMQPair;
  zipcode, temperature, relhumidity: Integer;
  update: string;
begin
  // Prepare our context and publisher
  Writeln('Starting weather server (5556)...');
  Z := TZeroMQ.Create(1);
  P := Z.Start(ZMQ.Publisher);
  P.Bind('tcp://*:5556');

  // Initialize random number generator
  Randomize;
  repeat
    // Get values that will fool the boss
    zipcode     := Random(100) + 10000;
    temperature := Random(215) - 80;
    relhumidity := Random(50) + 10;

    // Send message to all subscribers
    update := Format('%05d %d %d', [zipcode, temperature, relhumidity]);
    P.SendString(update);
  until False;
end;

begin
  try
    Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

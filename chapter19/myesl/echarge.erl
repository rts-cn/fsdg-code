-module(echarge).
-export([start/1]).

-define(FS_NODE, 'freeswitch@localhost').
-define(ERROR_PROMPT, "say:输入错误，请重新输入").

start(Ref) ->
    NewPid = spawn(fun() -> loop() end),
    {Ref, NewPid}.

loop() ->
     receive
          {call, {event, [UUID | _Event]} } ->
               io:format("New call ~s~n", [UUID]),
               send_msg(UUID, answer, ""),
               send_msg(UUID, set, "tts_engine=tts_commandline"),
               send_msg(UUID, set, "tts_voice=Ting-Ting"),
               send_lock_msg(UUID, speak, "您好，欢迎使用空中充值服务"),
               ask_account_and_password(UUID),
               loop();

          {call_event, {event, [UUID | Event]} } ->
               process_event(UUID, Event),
               loop();

          ok -> loop();

          call_hangup -> io:format("Call hangup~n", []);

          _X ->
               io:format("Ignoring message ~p~n", [_X]),
               loop()
     end.

ask_account_and_password(UUID) ->
     send_lock_msg(UUID, set, "charge_state=WAIT_ACCOUNT"),
     send_lock_msg(UUID, play_and_get_digits,
          "4 5 3 5000 # 'say:请输入您的账号，以井号结束' "
          ?ERROR_PROMPT " charge_account ^\\d{4}$"),
     send_lock_msg(UUID, set, "charge_state=WAIT_PASSWORD"),
     send_lock_msg(UUID, play_and_get_digits,
          "4 5 3 5000 # 'say:请输入您的密码，以井号结束' "
          ?ERROR_PROMPT " charge_password ^\\d{4}$").

process_event(UUID, Event) ->
     Name = proplists:get_value(<<"Event-Name">>, Event),
     App = proplists:get_value(<<"Application">>, Event),
     State = proplists:get_value(<<"variable_charge_state">>, Event),
     io:format("Event: ~s, App: ~s State: ~s~n", [Name, App, State]),
     case Name of
          <<"CHANNEL_EXECUTE_COMPLETE">> when
               State =:= <<"WAIT_PASSWORD">>, App =:= <<"play_and_get_digits">> ->
               Account = proplists:get_value(<<"variable_charge_account">>, Event),
               Password = proplists:get_value(<<"variable_charge_password">>, Event),
               case check_account_password(Account, Password) of
                    true ->
                         io:format("Account ~s Balance: 100~n", [Account]),
                         send_lock_msg(UUID, speak, "您的余额是100元"),
                         send_lock_msg(UUID, speak, "再见"),
                         send_lock_msg(UUID, hangup, "");
                    false ->
                         send_lock_msg(UUID, speak, "账号密码错误"),
                         ask_account_and_password(UUID)
               end,
               loop();
          _ -> ok
     end.

check_account_password(Account, Password) ->
     Account =:= <<"1111">> andalso Password =:= <<"1111">>.

send_msg(UUID, Headers) when is_list(Headers) ->
     {sendmsg, ?FS_NODE} ! {sendmsg, binary_to_list(UUID), Headers}.

send_msg(UUID, App, Arg) ->
     send_msg(UUID, [
          {"call-command", "execute"},
          {"execute-app-name", atom_to_list(App)},
          {"execute-app-arg", Arg}
     ]).

send_lock_msg(UUID, App, Arg) ->
     send_msg(UUID, [
          {"call-command", "execute"},
          {"event-lock", "true"},
          {"execute-app-name", atom_to_list(App)},
          {"execute-app-arg", Arg}
     ]).

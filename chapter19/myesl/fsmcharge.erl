-module('fsmcharge').

-export([start/1, init/1, handle_info/3, terminate/3]).
-export([welcome/2, wait_account/2, wait_password/2,
    wait_play_balance/2, wait_play_goodby/2, wait_hangup/2]).

-define(FS_NODE, 'freeswitch@localhost').
-define(ERROR_PROMPT, "say:输入错误，请重新输入").
-define(LOG(Fmt, Args), io:format("~b: " ++ Fmt ++ "~n", [?LINE | Args])).

-record(state, {
    fsnode           :: atom(),                  % FreeSWITCH node name
    uuid             :: undefined | binary(),    % Channel uuid
    cid_name         :: undefined | binary(),    % Caller id name
    cid_number       :: undefined | binary()     % Caller id number
}).

start(Ref) ->
    {ok, NewPid} = gen_fsm:start(?MODULE, [], []),
    {Ref, NewPid}.

init([]) ->
    State = #state{fsnode = ?FS_NODE},
    {ok, welcome, State}.

%% The state machine
welcome({call, _Name, UUID, Event}, State) ->
    CidName = proplists:get_value(<<"Caller-Caller-ID-Name">>, Event),
    CidNumber = proplists:get_value(<<"Caller-Caller-ID-Number">>, Event),
    ?LOG("New Call \"~s\" <~s>", [CidName, CidNumber]),
    send_msg(UUID, answer, ""),
    send_msg(UUID, set, "tts_engine=tts_commandline"),
    send_msg(UUID, set, "tts_voice=Ting-Ting"),
    send_msg(UUID, speak, "您好，欢迎使用空中充值服务"),
    {next_state, welcome,
        State#state{uuid=UUID, cid_name=CidName, cid_number=CidNumber}};


welcome({call_event, <<"CHANNEL_EXECUTE_COMPLETE">>, UUID, Event}, State) ->
    case proplists:get_value(<<"Application">>, Event) of
        <<"speak">> ->
            send_msg(UUID, play_and_get_digits,
                "4 5 3 5000 # 'say:请输入您的账号，以井号结束' "
                ?ERROR_PROMPT " charge_account ^\\d{4}$"),
            {next_state, wait_account, State};
        _ ->
            {next_state, welcome, State}
    end;

welcome(_Any, State) -> {next_state, welcome, State}.

wait_account({call_event, <<"CHANNEL_EXECUTE_COMPLETE">>, UUID, _Event}, State) ->
    send_msg(UUID, play_and_get_digits,
        "4 5 3 5000 # 'say:请输入您的密码，以井号结束' "
        ?ERROR_PROMPT " charge_password ^\\d{4}$"),
    {next_state, wait_password, State};

wait_account(_Any, State) -> {next_state, wait_account, State}.

wait_password({call_event, <<"CHANNEL_EXECUTE_COMPLETE">>, UUID, Event}, State) ->
    Account = proplists:get_value(<<"variable_charge_account">>, Event),
    Password = proplists:get_value(<<"variable_charge_password">>, Event),

    case check_account_password(Account, Password) of
        true ->
            ?LOG("Account: ~s, Balance: 100", [Account]),
            send_msg(UUID, speak, "您的余额是100元"),
            {next_state, wait_play_balance, State};
        false ->
            send_msg(UUID, speak, "账号密码错误"),
            {next_state, welcome, State}
    end;

wait_password(_Any, State) -> {next_state, wait_password, State}.

wait_play_balance({call_event, <<"CHANNEL_EXECUTE_COMPLETE">>, UUID, _Event}, State) ->
    send_msg(UUID, speak, "再见"),
    {next_state, wait_play_goodby, State};

wait_play_balance(_Any, State) -> {next_state, wait_play_balance, State}.

wait_play_goodby({call_event, <<"CHANNEL_EXECUTE_COMPLETE">>, UUID, _Event}, State) ->
    send_msg(UUID, hangup, ""),
    {next_state, wait_hangup, State};

wait_play_goodby(_Any, State) -> {next_state, wait_play_goodby, State}.

wait_hangup({call_event, <<"CHANNEL_HANGUP_COMPLETE">>, _UUID, Event}, State) ->
    Duration = proplists:get_value(<<"variable_duration">>, Event),
    Billsec = proplists:get_value(<<"variable_billsec">>, Event),
    ?LOG("Call End, Duration: ~s Billsec: ~s", [Duration, Billsec]),
    {stop, normal, State};

wait_hangup(_Any, State) ->
    {next_state, wait_hangup, State}.

handle_info(call_hangup, _StateName, State) ->
    {stop, normal, State};

handle_info({EventType, {event, [UUID | Event]}}, StateName, State) ->
    EventName = proplists:get_value(<<"Event-Name">>, Event),
    ?LOG("State: ~s Event: ~s", [StateName, EventName]),
    % ?MODULE:StateName({EventType, EventName, UUID, Event}, State);
    gen_fsm:send_event(self(), {EventType, EventName, UUID, Event}),
    {next_state, StateName, State};

handle_info(_Any, StateName, State) ->
    {next_state, StateName, State}.

terminate(normal, _StateName, _State) -> ok;
terminate(_Reason, _StateName, #state{uuid = UUID}) when UUID =/= undefined ->
    % do some clean up here
    send_msg(UUID, hangup, ""),
    ok.

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

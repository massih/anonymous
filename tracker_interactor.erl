%%Author: Massih
%%Creation Date: 2-Nov-2011
-module(tracker_interactor).
-export([init/1,start_link/1,handle_call/3]).
-behaviour(gen_server).
-include("defs.hrl").


init(Data)->
    {ok,Data}.

terminate(_Reason,Data)->
    ok.

start_link(Data)->
    gen_server:start_link(?MODULE,Data,[]).


send_request(URL)->
    inets:start(),
    httpc:request(URL).

make_url(T,Info)->
    {Downloaded,Left,Event,Numwant} = Info,
    T#tracker_info.url++"?info_hash="++T#tracker_info.info_hash++"&peer_id="++T#tracker_info.peer_id++"&port="++T#tracker_info.port++"&downloaded="++Downloaded++"&left="++Left++"&event="++Event++"&numwant="++Numwant .


response_handler(Result)->
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = newparse:decode(list_to_binary(Body)),
    {[{_,S},{_,L},{_,Interval},{_,Peers}],_}=Decoded_Body,
    %%io:format("seeds:~p  leechers:~p  interval :~p\n",[S,L,NewInterval]),
    [S,L,Interval,Peers].

handle_call({tracker_request_info,Info},_From,Data)->
    URL = make_url(Data,Info),
    Reply = case send_request(URL) of
	{ok,Result} ->
	    response_handler(Result);		 
	    %gen_server:cast(logger,{tracker_info,{Seeds,Leechers,Interval}}),
	    %gen_server:cast(logger,{peers_list,Peers}),
	{error,Reason} ->
	    {error_tracker_response,Reason}
	    %%gen_server:cast(logger,{tracker_request_error,Reason})
    end,
    {reply,Reply,Data}.
    


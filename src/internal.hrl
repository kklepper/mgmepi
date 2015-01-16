%% =============================================================================
%% =============================================================================

-include("../include/mgmepi.hrl").

-include_lib("baseline/include/baseline.hrl").

%% == define ==

-define(FS, ": ").
-define(LS, $\n).

-define(IS_BACKUP_ID(T), (is_integer(T) andalso (0 =< T))).

-define(IS_BACKUP_WAIT(T), (is_integer(T) andalso (0 =< T) andalso (2 >= T))).

-define(IS_EVENT_CATEGORY(T), (is_integer(T)
                               andalso (?NDB_MGM_MIN_EVENT_CATEGORY =< T)
                               andalso (?NDB_MGM_MAX_EVENT_CATEGORY >= T))).

-define(IS_EVENT_SEVERITY(T), (is_integer(T)
                               andalso (?NDB_MGM_MIN_EVENT_SEVERITY =< T)
                               andalso (?NDB_MGM_MAX_EVENT_SEVERITY >= T))).

-define(IS_LOGLEVEL(T), (is_integer(T) andalso (0 =< T) andalso (15 >= T))).

-define(IS_NODE(T), (is_integer(T) andalso (1 =< T) andalso (?MAX_NODES_ID >= T))).

-define(IS_NODE_TYPE(T), (is_integer(T)
                          andalso (?NDB_MGM_NODE_TYPE_MIN =< T)
                          andalso (?NDB_MGM_NODE_TYPE_MAX >  T))).

-define(IS_VERSION(T), (is_integer(T))). % > 5.1 (restart:V2)

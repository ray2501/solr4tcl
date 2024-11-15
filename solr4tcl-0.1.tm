# solr4tcl --
#
#	A lightweight Tcl client interface to Apache Solr
#
# Copyright (C) 2015-2016 Danilo Chang <ray2501@gmail.com>
#
# Retcltribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Retcltributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Retcltributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

package require Tcl 8.6-
package require TclOO
package require http
package require tdom
package require base64

package provide solr4tcl 0.1


#
# Solr_Request class: handle send request to Apache Solr
#
oo::class create Solr_Request {
    variable server
    variable ssl_enabled
    variable path
    variable solr_writer
    variable authtype
    variable username
    variable password
    variable response

    constructor {SERVER {SSL_ENABLED 0}} {
        set server $SERVER
        set path ""
        set ssl_enabled $SSL_ENABLED
        set solr_writer "xml"
        set authtype "no"
        set username ""
        set password ""
        set response ""

        if {$ssl_enabled} {
            if {[catch {package require tls}]==0} {
                http::register https 443 [list ::tls::socket -ssl3 0 -ssl2 0 -tls1 1]
            } else {
                error "SSL_ENABLED needs package tls..."
            }
        }
    }

    destructor {
    }

    method setDocumentPath {PATH} {
        set path $PATH
    }

    method setAuthType {AUTHTYPE} {
        # setup to "no" or "basic"
        set authtype $AUTHTYPE
    }

    method setUsername {USERNAME} {
        set username $USERNAME
    }

    method setPassword {PASSWORD} {
        set password $PASSWORD
    }

    #
    # support type: xml, json and cvs
    #
    method setSolrWriter {WRITER} {
        set solr_writer $WRITER
    }

    method send_request {url method {headers ""} {data ""}} {
        variable tok

        if {[string compare -nocase $authtype "basic"]==0} {
            set auth "Basic [base64::encode $username:$password]"
            lappend headers Authorization $auth
        }

        try {
            if {[string length $data] < 1} {
                set tok [http::geturl $url -method $method -headers $headers]
            } else {
                set tok [http::geturl $url -method $method -headers $headers \
                             -query $data]
            }

            set ncode [::http::ncode $tok]
            set res [http::status $tok]
            set [namespace current]::response [http::data $tok]
        } on error {em} {
            return "error"
        } finally {
            if {[info exists tok]==1} {
                http::cleanup $tok
            }
        }

        # Check status code Unauthorized and Not Found
        if {$ncode == 401 || $ncode == 404} {
            return "error"
        }

        return $res
    }

    #
    # Call the /admin/ping servlet
    #
    method ping {} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        if {[string length $path] < 1} {
            append myurl "/admin/ping"
        } else {
            append myurl "/$path/admin/ping"
        }

        set headerl ""
        set res [my send_request $myurl HEAD $headerl]
        return $res
    }

    #
    # Simple search interface
    # params is a list, give this funcition name-value pair parameter
    #
    method search {query {offset 0} {limit 10} {params ""}} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        if {[string length $path] < 1} {
            append myurl "/select"
        } else {
            append myurl "/$path/select"
        }

        lappend params q $query
        lappend params wt $solr_writer
        lappend params start $offset
        lappend params rows $limit
        set querystring [http::formatQuery {*}$params]

        #
        # The return data format is defined by wt, $solr_writer setting.
        #
        set headerl [list Content-Type "application/x-www-form-urlencoded; charset=UTF-8"]
        set res [my send_request $myurl POST $headerl $querystring]

        return $response
    }

    #
    # parameters - a list include key-value pair
    #
    method add {parameters {OVERWRITE true} {BOOST "1.0"} {COMMIT true}} {
        set [namespace current]::response ""

        # Try to build our XML document
        set doc [dom createDocument add]

        set root [$doc documentElement]
        $root setAttribute overwrite $OVERWRITE

        set docnode [$doc createElement doc]
        $docnode setAttribute boost $BOOST
        $root appendChild $docnode

        foreach {key value} $parameters {
            set node [$doc createElement field]
            $node setAttribute name $key
            $node appendChild [$doc createTextNode $value]
            $docnode appendChild $node
        }

        set myaddString [$root asXML]
        set myurl "$server/solr"

        set params [list commit $COMMIT]
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/update?$querystring"
        } else {
            append myurl "/$path/update?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl POST $headerl $myaddString]

        return $response
    }

    #
    # xmldata - xml data string want to add
    #
    method addData {xmldata {COMMIT true}} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        set params [list commit $COMMIT]
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/update?$querystring"
        } else {
            append myurl "/$path/update?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl POST $headerl $xmldata]

        return $response
    }

    #
    # The <commit>  operation writes all documents loaded since the last
    # commit to one or more segment files on the disk
    #
    method commit {{WAITSEARCHER true} {EXPUNGEDELETES false}} {
        set [namespace current]::response ""
        set mycommitString "<commit waitSearcher=\"$WAITSEARCHER\" expungeDeletes=\"$EXPUNGEDELETES\"/>"
        set myurl "$server/solr"

        if {[string length $path] < 1} {
            append myurl "/update"
        } else {
            append myurl "/$path/update"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl POST $headerl $mycommitString]

        return $response
    }

    #
    # The <optimize> operation requests Solr to merge internal data structures
    # in order to improve search performance.
    #
    method optimize {{WAITSEARCHER true} {MAXSegments 1}} {
        set [namespace current]::response ""
        set myoptimizeString "<optimize waitSearcher=\"$WAITSEARCHER\" maxSegments=\"$MAXSegments\"/>"
        set myurl "$server/solr"

        if {[string length $path] < 1} {
            append myurl "/update"
        } else {
            append myurl "/$path/update"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl POST $headerl $myoptimizeString]

        return $response
    }

    #
    #  "Delete by ID" deletes the document with the specified ID
    #
    method deleteById {ID {COMMIT true}} {
        set [namespace current]::response ""
        set mydeleteString "<delete><id>$ID</id></delete>"
        set myurl "$server/solr"

        set params [list commit $COMMIT]
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/update?$querystring"
        } else {
            append myurl "/$path/update?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl POST $headerl $mydeleteString]

        return $response
    }

    #
    #  "Delete by Query" deletes all documents matching a specified query
    #
    method deleteByQuery {QUERY {COMMIT true}} {
        set [namespace current]::response ""
        set mydeleteString "<delete><query>$QUERY</query></delete>"
        set myurl "$server/solr"

        set params [list commit $COMMIT]
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/update?$querystring"
        } else {
            append myurl "/$path/update?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl POST $headerl $mydeleteString]

        return $response
    }

    #
    #  Uploading Data with solr by using Apache Tika
    #
    method upload {fileContent {FILENAME ""} {COMMIT true} {ExtractOnly false} {params ""}} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        lappend params commit $COMMIT extractOnly $ExtractOnly

        if {[string length $FILENAME] > 1} {
            lappend params "resource.name" $FILENAME
        }

        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/update/extract?$querystring"
        } else {
            append myurl "/$path/update/extract?$querystring"
        }

        set ext [file extension $FILENAME]
        set ext [string tolower $ext]

        if {[string compare ".xml" $ext] == 0} {
          set headerl [list Content-Type "text/xml; charset=UTF-8"]
        } elseif {[string compare ".json" $ext] == 0} {
          set headerl [list Content-Type "text/json; charset=UTF-8"]
        } elseif {[string compare ".csv" $ext] == 0} {
          set headerl [list Content-Type "text/csv; charset=UTF-8"]
        } else {
          set headerl [list Content-Type "application/octet-stream"]
        }
        set res [my send_request $myurl POST $headerl $fileContent]

        return $response
    }

    #
    # clean default is 'true':
    # clean tells whether to clean up the index before the indexing is started.
    #
    method full-import {{CLEAN true}} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        set params [list command full-import]
        lappend params clean $CLEAN
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/dataimport?$querystring"
        } else {
            append myurl "/$path/dataimport?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl GET $headerl]
        return $response
    }

    #
    # clean default is 'true':
    # clean tells whether to clean up the index before the indexing is started.
    #
    method delta-import {{CLEAN true}} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        set params [list command delta-import]
        lappend params clean $CLEAN
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/dataimport?$querystring"
        } else {
            append myurl "/$path/dataimport?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl GET $headerl]

        return $response
    }

    method abort-import {} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        set params [list command abort]
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/dataimport?$querystring"
        } else {
            append myurl "/$path/dataimport?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl GET $headerl]

        return $response
    }

    method import-status {} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        set params [list command status]
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/dataimport?$querystring"
        } else {
            append myurl "/$path/dataimport?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl GET $headerl]

        return $response
    }

    #
    # An Authentication API allows modifying user IDs and passwords.
    #
    method authentication {JSON_STRING} {
        set [namespace current]::response ""
        set myurl "$server/solr"
        append myurl "/admin/authentication"

        set headerl [list Content-Type "application/json"]
        set res [my send_request $myurl POST $headerl $JSON_STRING]

        return $response
    }

    #
    # List Collections - only works in SolrCloud mode
    #
    method list-collections {} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        set params [list action LIST]
        lappend params wt $solr_writer
        set querystring [http::formatQuery {*}$params]

        append myurl "/admin/collections?$querystring"

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl GET $headerl]

        return $response
    }

    #
    # Apache Solr 6.0 added support for executing Parallel SQL queries across
    # SolrCloud collections.
    # Currently works in SolrCloud mode only… no standalone mode yet.
    #
    method sql {QUERY} {
        set [namespace current]::response ""
        set myurl "$server/solr"

        set params [list stmt $QUERY]
        set querystring [http::formatQuery {*}$params]

        if {[string length $path] < 1} {
            append myurl "/sql?$querystring"
        } else {
            append myurl "/$path/sql?$querystring"
        }

        set headerl [list Content-Type "text/xml; charset=UTF-8"]
        set res [my send_request $myurl GET $headerl]

        return $response
    }
}


solr4tcl
=====

A [Tcl] (http://tcl.tk) lightweight client interface to [Apache Solr] (http://lucene.apache.org/solr/).
The library consists of a single [Tcl Module] (http://tcl.tk/man/tcl8.6/TclCmd/tm.htm#M9) file.

solr4tcl is using  Tcl built-in package http to send request
to [Aapache Solr] (http://lucene.apache.org/solr/) and get response.

This library requires package tdom.


Interface
=====

The library has 1 TclOO class, Solr_Request.

Provide below things:

 * A simple search interface
 * A simple interface to add, delete and update documents to the index (using XML Formatted Index Updates)
 * Uploading file data (with Solr by using Apache Tika)

### Example

Below is a simple example:

    package require solr4tcl

    set solrresquest [Solr_Request new "http://localhost:8983"]
    $solrresquest setDocumentPath gettingstarted

    # support xml, json or csv
    $solrresquest setSolrWriter xml

    set res [$solrresquest ping]
    if {[string compare -nocase $res "ok"]!=0} {
        puts "Apache Solr server returns not OK, close."
        exit
    }

Below is an example to upload example docs:

    package require solr4tcl

    set solrresquest [Solr_Request new "http://localhost:8983"]
    $solrresquest setDocumentPath gettingstarted

    # support xml, json or csv
    $solrresquest setSolrWriter xml

    set res [$solrresquest ping]
    if {[string compare -nocase $res "ok"]!=0} {
        puts "Apache Solr server returns not OK, close."
        exit
    }

    # setup example docs folder
    set folder "/home/danilo/Programs/solr-6.3.0/example/exampledocs"

    foreach file [glob -directory $folder -types f *.xml] {
        set size [file size $file]
        set fd [open $file {RDWR BINARY}]
        fconfigure $fd -blocking 1 -encoding binary -translation binary
        set data [read $fd $size]
        close $fd

        # Notice: we give Solr the path to record
        set res [$solrresquest upload $data $file]
        puts $res
    }

    # Commit and Optimize Operations
    set res [$solrresquest commit]
    puts $res

    set res [$solrresquest optimize]
    puts $res

Below is an example to upload example docs (via SSL, JSON and CSV files):

    package require solr4tcl

    set solrresquest [Solr_Request new "https://localhost:8984" 1]
    $solrresquest setDocumentPath mycollection
    $solrresquest setSolrWriter xml

    set res [$solrresquest ping]
    if {[string compare -nocase $res "ok"]!=0} {
        puts "Apache Solr server returns not OK, close."
        exit
    }

    # Get current folder
    set cur_folder [pwd]

    # Enter example docs folder and upload
    cd "/home/danilo/Programs/solr-6.3.0/example/exampledocs"

    # For json file
    foreach file [glob -types f *.json] {
        set size [file size $file]
        set fd [open $file {RDWR BINARY}]
        fconfigure $fd -blocking 1 -encoding binary -translation binary
        set data [read $fd $size]
        close $fd

        # Notice: we just give Solr the file name to record
        set res [$solrresquest upload $data $file]
        puts $res
    }

    # For csv file
    foreach file [glob -types f *.csv] {
        set size [file size $file]
        set fd [open $file {RDWR BINARY}]
        fconfigure $fd -blocking 1 -encoding binary -translation binary
        set data [read $fd $size]
        close $fd

        # Notice: we just give Solr the file name to record
        set res [$solrresquest upload $data $file]
        puts $res
    }

    cd $cur_folder

    # Commit and Optimize Operations
    set res [$solrresquest commit]
    puts $res

    set res [$solrresquest optimize]
    puts $res

Now try to search something:

    package require solr4tcl

    set solrresquest [Solr_Request new "http://localhost:8983"]
    $solrresquest setDocumentPath gettingstarted

    # support xml, json or csv
    $solrresquest setSolrWriter xml

    set res [$solrresquest ping]
    if {[string compare -nocase $res "ok"]!=0} {
        puts "Apache Solr server returns not OK, close."
        exit
    }

    # Search ipod
    set res [$solrresquest search "ipod"]
    # print the search result
    puts $res

The Data Import Handler (DIH) provides a mechanism for importing content
from a data store and indexing it.

Below is an example to invoke full-import command and
check status:

    package require solr4tcl
    package require tdom

    set solrresquest [Solr_Request new "https://localhost:8984" 1]
    $solrresquest setDocumentPath monetdb

    $solrresquest setSolrWriter xml

    # do a full import
    $solrresquest full-import

    # Check import status
    set res [$solrresquest import-status]
    set doc [dom parse $res]
    set root [$doc documentElement]
    set nodeList [$root selectNodes {/response/lst/lst/str}]
    foreach node $nodeList {
        set attr [$node getAttribute name]
        set number [$node text]
        puts "$attr: $number"
    }

    set nodeList [$root selectNodes {/response/lst/str[@name]}]
    foreach node $nodeList {
        set attr [$node getAttribute name]
        set number [$node text]
        puts "$attr $number"
    }

## HTTPS support

If user enables HTTPS support, below is an example:

    package require solr4tcl
    
    set solrresquest [Solr_Request new "https://localhost:8984" 1]

Please notice, I use [TLS extension] (http://tls.sourceforge.net/) to add https support. So https support needs TLS extension.

## Basic Authentication support

This function requires tcllib base64 package.

If user `Basic Authentication` enables support, below is an example to update user `solr`
default password `SolrRocks`:

    package require solr4tcl

    set solrresquest [Solr_Request new "https://localhost:8984" 1]
    $solrresquest setDocumentPath monetdb

    $solrresquest setSolrWriter xml
    $solrresquest setAuthType "basic"
    $solrresquest setUsername "solr"
    $solrresquest setPassword "SolrRocks"

    set res [$solrresquest ping]
    if {[string compare -nocase $res "ok"]!=0} {
        puts "Apache Solr server returns not OK, close."
        exit
    }

    set res [$solrresquest authentication {{"set-user": {"solr" : "Solr6Rocks"}}}]
    puts $res

And test it:

    package require solr4tcl

    set solrresquest [Solr_Request new "https://localhost:8984" 1]
    $solrresquest setDocumentPath monetdb

    # support xml, json or csv
    $solrresquest setSolrWriter xml
    $solrresquest setAuthType "basic"
    $solrresquest setUsername "solr"
    $solrresquest setPassword "Solr6Rocks"

    set res [$solrresquest ping]
    if {[string compare -nocase $res "ok"]!=0} {
        puts "Apache Solr server returns not OK, close."
        exit
    }

    set res [$solrresquest search "product"]
    puts $res

## Parallel SQL

Apache Solr 6.0 added support for executing Parallel SQL queries
across SolrCloud collections. Tables in the SQL query map directly
to SolrCloud collections.

Below is an example:

    package require solr4tcl

    set solrresquest [Solr_Request new "https://localhost:8984" 1]
    $solrresquest setDocumentPath mycollection

    $solrresquest setSolrWriter xml
    $solrresquest setAuthType "basic"
    $solrresquest setUsername "solr"
    $solrresquest setPassword "Solr6Rocks"

    set res [$solrresquest ping]
    if {[string compare -nocase $res "ok"]!=0} {
        puts "Apache Solr server returns not OK, close."
        exit
    }

    set res [$solrresquest sql "select id from mycollection"]
    # output format now only support JSON, even setup writer to xml
    puts $res


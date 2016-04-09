
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
    set folder "/home/danilo/Programs/solr-5.5.0/example/exampledocs"

    foreach file [glob -directory $folder -types f *.xml] {
        set size [file size $file]
        set fd [open $file {RDWR BINARY}]
        fconfigure $fd -blocking 1 -encoding binary -translation binary
        set data [read $fd $size]
        close $fd

        set res [$solrresquest upload $data $file]
        puts $res
    }

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

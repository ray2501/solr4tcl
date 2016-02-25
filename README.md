
solr4tcl
=====

A [Tcl] (http://tcl.tk) lightweight client interface to Apache Solr. The library consists of a single
[Tcl Module] (http://tcl.tk/man/tcl8.6/TclCmd/tm.htm#M9) file.

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
    set folder "c:/solr-5.5.0/example/exampledocs"

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

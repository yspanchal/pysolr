#!/bin/sh

set -e

SOLR_VERSION=4.7.2

if [ ! -f solr-${SOLR_VERSION}.tgz ]; then
    python get-solr-download-url.py $SOLR_VERSION | xargs curl -O
fi

echo "Extracting Solr ${SOLR_VERSION} to solr4/"
rm -rf solr4
mkdir solr4
tar -C solr4 -xf solr-${SOLR_VERSION}.tgz --strip-components 2 solr-${SOLR_VERSION}/example
tar -C solr4 -xf solr-${SOLR_VERSION}.tgz --strip-components 1 solr-${SOLR_VERSION}/dist solr-${SOLR_VERSION}/contrib

echo "Configuring Solr"
cd solr4
rm -rf example-DIH exampledocs
mv solr solrsinglecoreanduseless
mv multicore solr
cp -r solrsinglecoreanduseless/collection1/conf/* solr/core0/conf/
cp -r solrsinglecoreanduseless/collection1/conf/* solr/core1/conf/

# Fix paths for the content extraction handler:
perl -p -i -e 's|<lib dir="../../../contrib/|<lib dir="../../contrib/|'g solr/*/conf/solrconfig.xml
perl -p -i -e 's|<lib dir="../../../dist/|<lib dir="../../dist/|'g solr/*/conf/solrconfig.xml

# Add MoreLikeThis handler
perl -p -i -e 's|<!-- A Robust Example|<!-- More like this request handler -->\n  <requestHandler name="/mlt" class="solr.MoreLikeThisHandler" />\n\n\n  <!-- A Robust Example|'g solr/*/conf/solrconfig.xml

echo 'Starting server'
# We use exec to allow process monitors like run-tests.py to correctly kill the
# actual Java process rather than this launcher script:
exec java -Djava.awt.headless=true -Dapple.awt.UIElement=true -jar start.jar

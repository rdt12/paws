FROM sl:latest
RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm net-tools
RUN yum -y install emacs-nox perl perl-Getopt-Long bind-utils openssl nmap-ncat perl-Data-Compare perl-DateTime \
                   perl-DateTime-Format-ISO8601 perl-Digest-SHA perl-File-HomeDir perl-HTTP-Tiny perl-JSON-MaybeXS \
		   perl-Module-Info perl-Moose perl-MooseX-AttributeHelpers perl-MooseX-Getopt perl-MooseX-Types-Path-Class \
                   perl-Time-Piece perl-Path-Tiny perl-MooseX-Types-Path-Tiny perl-String-CRC32 perl-Throwable \
		   perl-URL-Encode-XS perl-URI-Encode perl-XML-Simple perl-PerlIO-utf8_strict perl-Pod-Eventual \
		   perl-File-Find-Object perl-Module-CPANTS-Analyse gcc make perl-App-cpanminus.noarch jq curl unzip  awscli \
		   && yum clean all && rm -rf /var/cache/yum 
RUN cpanm Net::Amazon::Signature::V4 List::Util && cpanm Paws Paws::Credential::File && cpanm Paws \
    && rm -rf /root/.cpanm

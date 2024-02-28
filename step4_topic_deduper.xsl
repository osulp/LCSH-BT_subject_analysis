<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace=""
    exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>

    <xsl:param name="iteration" select="'unspecified'"/>
    <!-- User specify an iteration or level number  -->

    <xsl:variable name="output_filename" select="concat($iteration, '-4_topic_list.xml')"/>

    <xsl:template match="/">
        <xsl:result-document href="{$output_filename}">
            <xsl:apply-templates/>
        </xsl:result-document>
    </xsl:template>

    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="term[label = preceding-sibling::term/label]"/>

</xsl:stylesheet>
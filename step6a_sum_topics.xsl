<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace=""
    exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>

    <xsl:param name="iteration" select="'final'"/>
    <!-- User specify an iteration number or designation -->

    <xsl:variable name="output_filename" select="concat($iteration, '-6_topic_model.xml')"/>

    <xsl:template match="topic_graph">
        <xsl:result-document href="{$output_filename}">
            <topic_model>
                <xsl:for-each select="term">
                    <xsl:sort order="descending" select="sum(original_descendants/term/@occurrences)"/>
                    <xsl:call-template name="term"/>
                </xsl:for-each>
            </topic_model>
        </xsl:result-document>
    </xsl:template>

    <xsl:template name="term">
        
        <xsl:variable name="size" select="sum(original_descendants/term/@occurrences)"/>
        <xsl:variable name="reps" select="count(original_descendants/term)"/>
        
        <term>
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="representative_headings" select="$reps"/>
            <xsl:attribute name="total_size" select="$size"/>
            <xsl:for-each select="narrower_terms/term">
                <xsl:sort order="descending" select="number(@occurrences)"/>
                <xsl:call-template name="term"/>
            </xsl:for-each>
        </term>
    </xsl:template>

</xsl:stylesheet>
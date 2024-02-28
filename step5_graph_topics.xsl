<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace=""
    exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>

    <xsl:param name="iteration" select="'final'"/>
    <!-- User specify an iteration number or designation -->

    <xsl:variable name="output_filename" select="concat($iteration, '-5_topic_graph.xml')"/>

    <xsl:template match="topic_list">
        <xsl:result-document href="{$output_filename}">
            <topic_graph>
                <xsl:for-each select="topic">
                    <xsl:call-template name="graph"/>
                </xsl:for-each>
            </topic_graph>
        </xsl:result-document>
    </xsl:template>

    <xsl:template name="graph">
        <term>
            <xsl:attribute name="label">
                <xsl:value-of select="label"/>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="not(occurrences)"/>
                <xsl:otherwise>
                    <xsl:attribute name="occurrences" select="occurrences/@self_or_subdiv"/>
                </xsl:otherwise>
            </xsl:choose>
            <original_descendants>
                <xsl:for-each-group select="descendant-or-self::*[occurrences]" group-by="label">
                    <term label="{current-grouping-key()}" occurrences="{occurrences/@self_or_subdiv}"/>
                </xsl:for-each-group>
            </original_descendants>
            <narrower_terms>
                <xsl:for-each select="narrower_terms/term">
                    <xsl:call-template name="graph"/>
                </xsl:for-each>
            </narrower_terms>
        </term>
    </xsl:template>

</xsl:stylesheet>
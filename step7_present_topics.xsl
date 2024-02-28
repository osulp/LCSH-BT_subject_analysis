<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace=""
    exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="text" encoding="UTF-8"/>
    <xsl:strip-space elements="*"/>

    <xsl:param name="iteration" select="'final'"/>
    <!-- User specify an iteration or level number  -->
    <xsl:param name="threshold" select="10"/>
    <xsl:param name="lower" select="5"/>
    <xsl:param name="upper" select="50"/>

    <xsl:variable name="output_filename" select="concat($iteration, '-7_topic_overview.csv')"/>
    <xsl:variable name="delim" select="','"/>
    <xsl:variable name="quote" select="'&quot;'"/>
    <xsl:variable name="newline" select="'&#10;'"/>
    
<xsl:template match="topic_model">
    <xsl:result-document href="{$output_filename}">
        <xsl:value-of select="concat('Top Level Topics; Threshold = ',$threshold,$delim,$delim,$newline,$newline)"/>
        <xsl:value-of select="concat('Label',$delim,'Number of Representative Subject Headings',$delim,'Total Size of Concept',$newline,$newline)"/>
        <xsl:for-each select="term[@total_size >= $threshold]">
            <xsl:call-template name="term"/>
        </xsl:for-each>
        <xsl:value-of select="$newline"/>
        <xsl:value-of select="concat('Right-Sized Topics; Upper Limit = ',$upper,'; Lower Limit = ',$lower,$delim,$delim,$newline,$newline)"/>
        <xsl:value-of select="concat('Label',$delim,'Number of Representative Subject Headings',$delim,'Total Size of Concept',$newline,$newline)"/>
        <xsl:for-each-group select="//term" group-by="@label">
            <xsl:sort order="descending" select="number(@total_size)"/>
            <xsl:choose>
                <xsl:when test="$upper >= @representative_headings and @representative_headings >= $lower">
                    <xsl:call-template name="term"/>
                </xsl:when>
            </xsl:choose>    
        </xsl:for-each-group>
        
    </xsl:result-document>
</xsl:template>

    <xsl:template name="term">

        <xsl:value-of select="concat($quote, @label, $quote, $delim)"/>
        <xsl:value-of select="concat(@representative_headings,$delim)"/>
        <xsl:value-of select="concat(@total_size,$newline)"/>

    </xsl:template>

</xsl:stylesheet>
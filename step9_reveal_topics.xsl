<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace=""
    exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="text" encoding="UTF-8"/>
    <xsl:strip-space elements="*"/>


    <xsl:param name="iteration" select="'final'"/>
    <!-- User specify an iteration or level number  -->
    <xsl:param name="lower" select="5"/>
    <xsl:param name="upper" select="50"/>
    
    <xsl:variable name="output_filename" select="concat($iteration, '-9_right-sized_topic_groupings.md')"/>
    <xsl:variable name="l1_bullet" select="'- '"/>
    <xsl:variable name="l2_bullet" select="'    - '"/>
    <xsl:variable name="newline" select="'&#10;'"/>
    
        
    <xsl:template match="topic_graph">
        <xsl:result-document href="{$output_filename}">
            <xsl:value-of select="concat('# Topic Groupings',$newline,$newline)"/>
            <xsl:value-of select="concat('The following are broader-term subject headings at any level of the hierarchy whose have at least ',$lower,' but not more than ',$upper,' unique subject heading descendants in the original dataset, followed by a list of their originally-occurring descendants.',$newline,$newline)"/>
            
            <xsl:for-each-group select="//term" group-by="@label">
                <xsl:sort order="descending" select="sum(original_descendants/term/@occurrences)"/>
                <xsl:variable name="orig" select="count(original_descendants/term)"/>
                <xsl:choose>
                    <xsl:when test="$upper >= $orig and $orig >= $lower">
                        <xsl:call-template name="term"/>
                    </xsl:when>
                </xsl:choose>
                
            </xsl:for-each-group>
        </xsl:result-document>
    </xsl:template>

    <xsl:template name="term">
        
        <xsl:variable name="size" select="sum(original_descendants/term/@occurrences)"/>
        <xsl:variable name="reps" select="count(original_descendants/term)"/>
        
        <xsl:value-of select="concat($l1_bullet,@label,' (SH: ',$reps,'; Size: ',$size,')',$newline)"/>
        <xsl:for-each select="original_descendants/term">
            <xsl:sort order="descending" select="number(@occurrences)"/>
            <xsl:value-of select="concat($l2_bullet,@label,' (',@occurrences,')',$newline)"/>
        </xsl:for-each>
        <xsl:value-of select="$newline"/>
    </xsl:template>

</xsl:stylesheet>
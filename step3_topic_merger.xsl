<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace=""
    exclude-result-prefixes="#all" version="2.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="iteration" select="'unspecified'"/>
    <!-- User specify an iteration or level number  -->
    
    <xsl:variable name="output_filename" select="concat($iteration,'-3_merged_topics.xml')"/>
    
    <xsl:template match="bt_list">

        <!-- Send output to a document -->
        <xsl:result-document href="{$output_filename}">
            <topic_list>
                
                <!-- Meta section calculates counts for validation and tracking -->
                
                <meta>
                    <xsl:variable name="origcount" select="count(distinct-values(//label[following-sibling::occurrences/@self_or_subdiv != '0']))"/>
                    <xsl:variable name="refcount" select="count(distinct-values(//reference))"/>
                    <xsl:variable name="btcount" select="count(distinct-values(//broader_term/label))"/>
                    <xsl:variable name="terminal_topics" select="count(//broader_term[terminus/@value = 'true'])"/>
                    <xsl:variable name="ref_matches" select="count(distinct-values(//broader_term/label[. = //reference/label]))"/>
                    <xsl:variable name="term_matches" select="count(distinct-values(//broader_term/label[. = //term/label]))"/>
                    <xsl:variable name="dupe_bts" select="$ref_matches + $term_matches"/>
                    <xsl:variable name="remaining_bts" select="$btcount - $dupe_bts"/>
                    <unique_root_subjects>
                        <xsl:value-of select="$origcount"/>
                    </unique_root_subjects>
                    <previousRound_topic_count>
                        <xsl:value-of select="$refcount + $terminal_topics"/>
                    </previousRound_topic_count>
                    <reference_topic_count>
                        <xsl:value-of select="$refcount"/>
                    </reference_topic_count>
                    <terminal_topic_count>
                        <xsl:value-of select="$terminal_topics"/>
                    </terminal_topic_count>
                    <fetched_bt_count>
                        <xsl:value-of select="$btcount - $terminal_topics"/>
                    </fetched_bt_count>
                    <duplicate_bts>
                        <total_matches>
                            <xsl:value-of select="$dupe_bts"/>
                        </total_matches>
                        <reference_matches>
                            <xsl:value-of select="$ref_matches"/>
                        </reference_matches>
                        <narrower_term_matches>
                            <xsl:value-of select="$term_matches"/>
                        </narrower_term_matches>
                    </duplicate_bts>
                    <calculated_topic_count>
                        <xsl:value-of select="$remaining_bts"/>
                    </calculated_topic_count>
                    <nextRound_lookup_count>
                        <xsl:value-of select="$remaining_bts - $terminal_topics"/>
                    </nextRound_lookup_count>
                </meta>
                
                <!-- ***** End meta section; begin topic entries ***** -->

                
                <xsl:for-each-group select="broader_term" group-by="label"><!-- For each set of broader terms in the bt_list that has the same label... -->
                    
                    <!-- Check whether that term occurs lower in the hierarchy -->
                    <xsl:variable name="topic_label" select="current-grouping-key()"/>
                    <xsl:variable name="prev_match" select="//*[not(name()='broader_term')][label = $topic_label]"/>
                    
                    <xsl:choose>
                        
                        <xsl:when test="$prev_match"/><!-- If the term has a match lower in the hierarchy, do nothing at this point (it will be merged into the new model hierarchy later) -->
                        
                        <!-- If the term is new, create a topic entry -->
                        <xsl:otherwise>
                            
                            <!-- Identify all term entries that have this label -->
                            <xsl:variable name="any_match" select="//*[label = $topic_label]"/>
                            
                            <topic>
                                <label>
                                    <xsl:value-of select="$topic_label"/>
                                </label>
                                
                                <!-- Copy any instance of an occurrences element for this term -->
                                <xsl:if test="$any_match/occurrences">
                                    <xsl:copy-of select="$any_match/occurrences"/>    
                                </xsl:if>
                                
                                <!-- Set up narrower terms container and call a template -->
                                <narrower_terms>
                                    <xsl:for-each select="current-group()">
                                        <xsl:call-template name="narrower_terms"/>
                                    </xsl:for-each>
                                </narrower_terms>
                                
                                <!-- Copy any instance of a terminus element for this term -->
                                <xsl:if test="$any_match/terminus">
                                    <xsl:copy-of select="$any_match/terminus"/>
                                </xsl:if>
                            </topic>

                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each-group>
            </topic_list>
        </xsl:result-document>
    </xsl:template>
    
    <xsl:template name="narrower_terms">
        
        <!-- For each previously identified narrower-term element, call a template to create a term entry -->
        <xsl:for-each select="narrower_terms/term">
            <xsl:call-template name="term"/>
        </xsl:for-each>
        
        <!-- For each reference element, representing a top-level topic in the previous iteration, call a template to create a term entry -->
        <xsl:for-each select="reference">
            <xsl:call-template name="term"/>
        </xsl:for-each>
        
    </xsl:template>
    
    <xsl:template name="term">
        <xsl:variable name="term_label" select="label"/>    
        
        <!-- Construct the entry for a narrower term at some level of hierarchy within a topic, based on its entry/ies from previous iterations -->
        <term>
            
            <!-- Replicate the label and occurrences elements from previous iterations -->
            <xsl:copy-of select="label | occurrences"/>
            <narrower_terms>  
                
                <!-- Call the narrower terms template to recursively build the hierarchy -->
                <xsl:call-template name="narrower_terms"/>
                
                <!-- Merge any fetched broader terms that are matches to this term into the hierarchy -->
                <xsl:for-each-group select="//broader_term[label = $term_label]" group-by="label">
                    <xsl:for-each select="current-group()">
                        <xsl:call-template name="narrower_terms"/>
                    </xsl:for-each>
                </xsl:for-each-group>
                
            </narrower_terms>
            
            <!-- A narrower term will not be terminal, so no need to duplicate a terminus element here -->
        </term>
        
    </xsl:template>
</xsl:stylesheet>
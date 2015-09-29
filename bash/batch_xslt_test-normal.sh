#!/bin/bash
# dc:rights [ 'Copyright 2015 RuleML Inc. -- Licensed under the RuleML Specification License, Version 1.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://ruleml.org/licensing/RSL1.0-RuleML. Disclaimer: THIS SPECIFICATION IS PROVIDED "AS IS" AND ANY EXPRESSED OR IMPLIED WARRANTIES, ..., EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. See the License for the specifics governing permissions and limitations under the License.' ]
# Prerequisites: batch_rnc2xsd.sh
# Dependecies: 
# aux_valxsd.sh
#  Validate RuleML instances by XSD
# Instructions:
# run this script from the command line or another script after batch_rnc2xsd.sh
# FIXME use configuration script to validate test files against multiple schemas, including fail tests
# This will remove the fragile schema detection method now implemented.
#
# globstar is only available in bash 4
#shopt -s globstar
shopt -s nullglob
BASH_HOME=$( cd "$(dirname "$0")" ; pwd -P )/ ;. "${BASH_HOME}path_config.sh";

# creates the normalization test directory if they doesn't exist, and clears it, in case it already has contents
mkdir -p "${NORMAL_SUITE_HOME}"
rm "${NORMAL_SUITE_HOME}"* >> /dev/null 2>&1


  cschemaname="naffologeq_compact4xsd.xsd"
  cfile="${XSD_HOME}${cschemaname}"       
  "${BASH_HOME}aux_valxsd.sh" "${cfile}"
  exitvalue=$?
  echo ${exitvalue}
  if [[ "${exitvalue}" -ne "0" ]]; then
       echo "Schema Validation Failed for ${cschemaname}"
       exit 1
   fi   

  schemaname="naffologeq_normal.xsd"
  sfile="${XSD_HOME}${schemaname}"       
  "${BASH_HOME}aux_valxsd.sh" "${sfile}"
  exitvalue=$?
  echo ${exitvalue}
  if [[ "${exitvalue}" -ne "0" ]]; then
       echo "Schema Validation Failed for ${schemaname}"
       exit 1
   fi   

schemaname2="naffologeq_normal.rnc"
  sfile2="${TEST_HOME}${schemaname2}"       
  "${BASH_HOME}aux_valrnc.sh" "${sfile2}"
  exitvalue=$?
  echo ${exitvalue}
  if [[ "${exitvalue}" -ne "0" ]]; then
       echo "Schema Validation Failed for ${schemaname2}"
       exit 1
   fi   

# Apply normalization XSLT transforamtions
# transform files in TEST_SUITE_HOME ending in .ruleml
# output to NORMAL_SUITE_HOME
# FIXME write an aux script for the xslt call
# FIXME use a find command to get RuleML files at any depth
# e.g. find "${XSD_TEST_SUITE_HOME}" -name '*.ruleml' -exec  "${BASH_HOME}aux_xslt.sh" {} "${NORMAL_XSLT_HOME}1.02_normalizer.xslt" "${NORMAL_SUITE_HOME}${filename}"
for f in "${XSD_TEST_SUITE_HOME}"*/*.ruleml "${XSD_TEST_SUITE_HOME}"*/*/*.ruleml
do
  filename=$(basename "$f")
  echo "Transforming  ${filename}"
  java -jar "${SAX_HOME}saxon9ee.jar" -s:"${f}" -xsl:"${NORMAL_XSLT_HOME}1.02_normalizer.xslt"  -o:"${NORMAL_SUITE_HOME}${filename}"
  if [[ "$?" -ne "0" ]]; then
     echo "XSLT Transformation Failed for  ${filename}"
     exit 1
   fi
done

for file in "${NORMAL_SUITE_HOME}"*.ruleml
do
  filename=$(basename "${file}")
  echo "File ${filename}"
    "${BASH_HOME}aux_valxsd.sh" "${cfile}" "${file}"
    exitvalue=$?
    if [[ "${exitvalue}" -ne "1" ]]; then
          echo "Normal Validation Succeeded for Compact ${file}"
          exit 1
    fi       
    "${BASH_HOME}aux_valxsd.sh" "${sfile}" "${file}"
    exitvalue=$?
    if [[ ! "${file}" =~ fail ]] && [[ "${exitvalue}" -ne "0" ]]; then
          echo "Validation Failed for Normal ${file}"
          exit 1
    fi       
    "${BASH_HOME}aux_valrnc.sh" "${sfile2}" "${file}"
    exitvalue=$?
    if [[ ! "${file}" =~ fail ]] && [[ "${exitvalue}" -ne "0" ]]; then
          echo "Validation Failed for Compact ${file}"
          exit 1
    fi       
done

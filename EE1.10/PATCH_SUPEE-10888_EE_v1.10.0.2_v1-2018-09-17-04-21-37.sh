#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-10888_EE_v1.10.0.2 | EE_1.10.0.2 | v1 | 85d5558c05eba20fe851f6e2308fc9b0f95ac5d3 | Tue Sep 11 10:48:12 2018 +0300 | ee-1.10.0.2-dev

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/GiftRegistry/Helper/Data.php app/code/core/Enterprise/GiftRegistry/Helper/Data.php
index 645c72456fb..5957eca4f59 100644
--- app/code/core/Enterprise/GiftRegistry/Helper/Data.php
+++ app/code/core/Enterprise/GiftRegistry/Helper/Data.php
@@ -247,4 +247,15 @@ class Enterprise_GiftRegistry_Helper_Data extends Mage_Core_Helper_Abstract
         }
         return true;
     }
+
+    /**
+     * Validate attribute code value
+     *
+     * @param string $code
+     * @return boolean
+     */
+    public function validateAttributeCode($code)
+    {
+        return strcmp($code, str_replace(['<', '>', '&'], '', $code)) === 0;
+    }
 }
diff --git app/code/core/Enterprise/GiftRegistry/Model/Attribute/Processor.php app/code/core/Enterprise/GiftRegistry/Model/Attribute/Processor.php
index f64eb615bf6..684429e12c6 100644
--- app/code/core/Enterprise/GiftRegistry/Model/Attribute/Processor.php
+++ app/code/core/Enterprise/GiftRegistry/Model/Attribute/Processor.php
@@ -38,6 +38,7 @@ class Enterprise_GiftRegistry_Model_Attribute_Processor extends Mage_Core_Model_
      *
      * @param Enterprise_GiftRegistry_Model_Type $type
      * @return string
+     * @throws Mage_Core_Exception
      */
     public function processData($type)
     {
@@ -48,9 +49,19 @@ class Enterprise_GiftRegistry_Model_Attribute_Processor extends Mage_Core_Model_
                 $groups = array();
                 $attribute_groups = Mage::getSingleton('enterprise_giftregistry/attribute_config')
                     ->getAttributeGroups();
+                $helper = Mage::helper('enterprise_giftregistry');
                 foreach ($data as $attributes) {
                     foreach ($attributes as $attribute) {
-                        if (array_key_exists($attribute['group'], $attribute_groups)) {
+                        if (isset($attribute['options'])) {
+                            foreach ($attribute['options'] as $option) {
+                                if (!$helper->validateAttributeCode($option['code'])) {
+                                    Mage::throwException($helper->__('Failed to save gift registry.'));
+                                }
+                            }
+                        }
+                        if (array_key_exists($attribute['group'], $attribute_groups)
+                            && ($helper->validateAttributeCode($attribute['code']))
+                        ) {
                             if ($attribute['group'] == self::XML_REGISTRANT_NODE) {
                                 $group = self::XML_REGISTRANT_NODE;
                             } else {
@@ -58,9 +69,7 @@ class Enterprise_GiftRegistry_Model_Attribute_Processor extends Mage_Core_Model_
                             }
                             $groups[$group][$attribute['code']] = $attribute;
                         } else {
-                            Mage::throwException(
-                                Mage::helper('enterprise_giftregistry')->__('Failed to save gift registry.')
-                            );
+                            Mage::throwException($helper->__('Failed to save gift registry.'));
                         }
                     }
                 }
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 46aa95e4173..feaa5421302 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -40,6 +40,10 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
 
     protected $_eventPrefix = 'admin_user';
 
+    /** Configuration paths for notifications */
+    const XML_PATH_ADDITIONAL_EMAILS             = 'general/additional_notification_emails/admin_user_create';
+    const XML_PATH_NOTIFICATION_EMAILS_TEMPLATE  = 'admin/emails/admin_notification_email_template';
+
     /**
      * @var Mage_Admin_Model_Roles
      */
@@ -442,4 +446,52 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         return (array)$errors;
     }
 
+    /**
+     * Send notification to general Contact and additional emails when new admin user created.
+     * You can declare additional emails in Mage_Core general/additional_notification_emails/admin_user_create node.
+     *
+     * @param $user
+     * @return $this
+     */
+    public function sendAdminNotification($user)
+    {
+        // define general contact Name and Email
+        $generalContactName = Mage::getStoreConfig('trans_email/ident_general/name');
+        $generalContactEmail = Mage::getStoreConfig('trans_email/ident_general/email');
+
+        // collect general and additional emails
+        $emails = $this->getUserCreateAdditionalEmail();
+        $emails[] = $generalContactEmail;
+
+        /** @var $mailer Mage_Core_Model_Email_Template_Mailer */
+        $mailer    = Mage::getModel('core/email_template_mailer');
+        $emailInfo = Mage::getModel('core/email_info');
+        $emailInfo->addTo(array_filter($emails), $generalContactName);
+        $mailer->addEmailInfo($emailInfo);
+
+        // Set all required params and send emails
+        $mailer->setSender(array(
+            'name'  => $generalContactName,
+            'email' => $generalContactEmail,
+        ));
+        $mailer->setStoreId(0);
+        $mailer->setTemplateId(Mage::getStoreConfig(self::XML_PATH_NOTIFICATION_EMAILS_TEMPLATE));
+        $mailer->setTemplateParams(array(
+            'user' => $user,
+        ));
+        $mailer->send();
+
+        return $this;
+    }
+
+    /**
+     * Get additional emails for notification from config.
+     *
+     * @return array
+     */
+    public function getUserCreateAdditionalEmail()
+    {
+        $emails = str_replace(' ', '', Mage::getStoreConfig(self::XML_PATH_ADDITIONAL_EMAILS));
+        return explode(',', $emails);
+    }
 }
diff --git app/code/core/Mage/Admin/etc/config.xml app/code/core/Mage/Admin/etc/config.xml
index 20fd50354e1..bd1a6ff31ba 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -67,6 +67,7 @@
         <admin>
             <emails>
                 <forgot_email_template>admin_emails_forgot_email_template</forgot_email_template>
+                <admin_notification_email_template>admin_emails_admin_notification_email_template</admin_notification_email_template>
                 <forgot_email_identity>general</forgot_email_identity>
             </emails>
         </admin>
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
index 79590c663ed..955bf11d137 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
@@ -159,9 +159,10 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Super_Config extends Mage_Ad
         $attributes = $this->_getProduct()->getTypeInstance(true)
             ->getUsedProductAttributes($this->_getProduct());
         foreach ($attributes as $attribute) {
+            $attributeLabel = $this->escapeHtml($product->getAttributeText($attribute->getAttributeCode()));
             $data[] = array(
                 'attribute_id' => $attribute->getId(),
-                'label'        => $product->getAttributeText($attribute->getAttributeCode()),
+                'label'        => $attributeLabel,
                 'value_index'  => $product->getData($attribute->getAttributeCode())
             );
         }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Massaction/Abstract.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Massaction/Abstract.php
index 4325e1c8eb8..4fdc529a70d 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Massaction/Abstract.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Massaction/Abstract.php
@@ -185,7 +185,7 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Massaction_Abstract extends Mage
     public function getSelectedJson()
     {
         if($selected = $this->getRequest()->getParam($this->getFormFieldNameInternal())) {
-            $selected = explode(',', $selected);
+            $selected = explode(',', $this->quoteEscape($selected));
             return join(',', $selected);
 //            return Mage::helper('core')->jsonEncode($selected);
         } else {
@@ -202,7 +202,7 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Massaction_Abstract extends Mage
     public function getSelected()
     {
         if($selected = $this->getRequest()->getParam($this->getFormFieldNameInternal())) {
-            $selected = explode(',', $selected);
+            $selected = explode(',', $this->quoteEscape($selected));
             return $selected;
         } else {
             return array();
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 79979b29429..cc3f6b51beb 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -38,6 +38,7 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
 {
     const XML_INVALID                             = 'invalidXml';
     const INVALID_TEMPLATE_PATH                   = 'invalidTemplatePath';
+    const INVALID_BLOCK_NAME                      = 'invalidBlockName';
     const PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR = 'protectedAttrHelperInActionVar';
 
     /**
@@ -56,7 +57,18 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
         '*//template',
         '*//@template',
         '//*[@method=\'setTemplate\']',
-        '//*[@method=\'setDataUsingMethod\']//*[text() = \'template\']/../*'
+        '//*[@method=\'setDataUsingMethod\']//*[contains(translate(text(),
+        \'ABCDEFGHIJKLMNOPQRSTUVWXYZ\', \'abcdefghijklmnopqrstuvwxyz\'), \'template\')]/../*',
+    );
+
+    /**
+     * Disallowed template name
+     *
+     * @var array
+     */
+    protected $_disallowedBlock = array(
+        'Mage_Install_Block_End',
+        'Mage_Rss_Block_Order_New',
     );
 
     /**
@@ -91,6 +103,7 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
                 self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
                     'Invalid template path used in layout update.'
                 ),
+                self::INVALID_BLOCK_NAME => Mage::helper('adminhtml')->__('Disallowed block name for frontend.'),
             );
         }
         return $this;
@@ -125,6 +138,10 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
                 Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'));
         }
 
+        if ($value->xpath($this->_getXpathBlockValidationExpression())) {
+            $this->_error(self::INVALID_BLOCK_NAME);
+            return false;
+        }
         // if layout update declare custom templates then validate their paths
         if ($templatePaths = $value->xpath($this->_getXpathValidationExpression())) {
             try {
@@ -154,6 +171,20 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
         return implode(" | ", $this->_disallowedXPathExpressions);
     }
 
+    /**
+     * Returns xPath for validate incorrect block name
+     *
+     * @return string xPath for validate incorrect block name
+     */
+    protected function _getXpathBlockValidationExpression() {
+        $xpath = "";
+        if (count($this->_disallowedBlock)) {
+            $xpath = "//block[@type='";
+            $xpath .= implode("'] | //block[@type='", $this->_disallowedBlock) . "']";
+        }
+        return $xpath;
+    }
+
     /**
      * Validate template path for preventing access to the directory above
      * If template path value has "../" @throws Exception
@@ -162,7 +193,11 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      */
     protected function _validateTemplatePath(array $templatePaths)
     {
+        /**@var $path Varien_Simplexml_Element */
         foreach ($templatePaths as $path) {
+            if ($path->hasChildren()) {
+                $path = stripcslashes(trim((string) $path->children(), '"'));
+            }
             if (strpos($path, '..' . DS) !== false) {
                 throw new Exception();
             }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index e54de00ab6d..a5774320684 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -982,6 +982,16 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
         }
 
         $product->addData($this->getRequest()->getParam('simple_product', array()));
+
+        $productSku = $product->getSku();
+        if ($productSku && $productSku != Mage::helper('core')->stripTags($productSku)) {
+            $result['error'] = array(
+                'message' => $this->__('HTML tags are not allowed in SKU attribute.')
+            );
+            $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
+            return;
+        }
+
         $product->setWebsiteIds($configurableProduct->getWebsiteIds());
 
         $autogenerateOptions = array();
diff --git app/code/core/Mage/Adminhtml/controllers/Permissions/UserController.php app/code/core/Mage/Adminhtml/controllers/Permissions/UserController.php
index 1df59cd8d7f..d8138b2e46d 100644
--- app/code/core/Mage/Adminhtml/controllers/Permissions/UserController.php
+++ app/code/core/Mage/Adminhtml/controllers/Permissions/UserController.php
@@ -96,6 +96,8 @@ class Mage_Adminhtml_Permissions_UserController extends Mage_Adminhtml_Controlle
 
             $id = $this->getRequest()->getParam('user_id');
             $model = Mage::getModel('admin/user')->load($id);
+            // @var $isNew flag for detecting new admin user creation.
+            $isNew = !$model->getId() ? true : false;
             if (!$model->getId() && $id) {
                 Mage::getSingleton('adminhtml/session')->addError($this->__('This user no longer exists.'));
                 $this->_redirect('*/*/');
@@ -125,6 +127,10 @@ class Mage_Adminhtml_Permissions_UserController extends Mage_Adminhtml_Controlle
 
             try {
                 $model->save();
+                // Send notification to General and additional contacts (if declared) that a new admin user was created.
+                if (Mage::getStoreConfigFlag('admin/security/crate_admin_user_notification') && $isNew) {
+                    Mage::getModel('admin/user')->sendAdminNotification($model);
+                }
                 if ( $uRoles = $this->getRequest()->getParam('roles', false) ) {
                     /*parse_str($uRoles, $uRoles);
                     $uRoles = array_keys($uRoles);*/
diff --git app/code/core/Mage/Adminhtml/etc/config.xml app/code/core/Mage/Adminhtml/etc/config.xml
index a17cef2baf1..8d59f94bb09 100644
--- app/code/core/Mage/Adminhtml/etc/config.xml
+++ app/code/core/Mage/Adminhtml/etc/config.xml
@@ -54,6 +54,11 @@
                     <file>admin_password_new.html</file>
                     <type>html</type>
                 </admin_emails_forgot_email_template>
+                <admin_emails_admin_notification_email_template>
+                    <label>New Admin User Create Notification</label>
+                    <file>admin_new_user_notification.html</file>
+                    <type>html</type>
+                </admin_emails_admin_notification_email_template>
             </email>
         </template>
 
diff --git app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
index 40e3a919abb..cf5b774b94b 100644
--- app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
+++ app/code/core/Mage/Checkout/Model/Api/Resource/Customer.php
@@ -153,7 +153,7 @@ class Mage_Checkout_Model_Api_Resource_Customer extends Mage_Checkout_Model_Api_
         $customer->setPasswordCreatedAt(time());
         $quote->setCustomer($customer)
             ->setCustomerId(true);
-
+        $quote->setPasswordHash('');
         return $this;
     }
 
diff --git app/code/core/Mage/Checkout/Model/Type/Onepage.php app/code/core/Mage/Checkout/Model/Type/Onepage.php
index a88a59aa873..f2708c79f0d 100644
--- app/code/core/Mage/Checkout/Model/Type/Onepage.php
+++ app/code/core/Mage/Checkout/Model/Type/Onepage.php
@@ -662,6 +662,7 @@ class Mage_Checkout_Model_Type_Onepage
         $customer->setPasswordCreatedAt($passwordCreatedTime);
         $quote->setCustomer($customer)
             ->setCustomerId(true);
+        $quote->setPasswordHash('');
     }
 
     /**
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
index 441aeced88f..46f5d29ab0e 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Images/Storage.php
@@ -276,11 +276,13 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
         }
         $uploader->setAllowRenameFiles(true);
         $uploader->setFilesDispersion(false);
-        $uploader->addValidateCallback(
-            Mage_Core_Model_File_Validator_Image::NAME,
-            Mage::getModel('core/file_validator_image'),
-            'validate'
-        );
+        if ($type == 'image') {
+            $uploader->addValidateCallback(
+                Mage_Core_Model_File_Validator_Image::NAME,
+                Mage::getModel('core/file_validator_image'),
+                'validate'
+            );
+        }
         $result = $uploader->save($targetPath);
 
         if (!$result) {
@@ -292,8 +294,9 @@ class Mage_Cms_Model_Wysiwyg_Images_Storage extends Varien_Object
         Mage::helper('core/file_storage_database')->saveFile($filePath);
 
         // create thumbnail
-        $this->resizeFile($targetPath . DS . $uploader->getUploadedFileName(), true);
-
+        if ($type == 'image') {
+            $this->resizeFile($targetPath . DS . $uploader->getUploadedFileName(), true);
+        }
         $result['cookie'] = array(
             'name'     => session_name(),
             'value'    => $this->getSession()->getSessionId(),
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 478862b4e44..4851952174e 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -353,6 +353,11 @@
             <reprocess_images>
                 <active>1</active>
             </reprocess_images>
+            <!-- Additional email for notifications -->
+            <additional_notification_emails>
+                <!-- On creating a new admin user. You can specify several emails separated by commas. -->
+                <admin_user_create></admin_user_create>
+            </additional_notification_emails>
         </general>
     </default>
     <stores> <!-- declare routers for installation process -->
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index 152001e9ab7..ff07d7d27a8 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -1031,6 +1031,16 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </extensions_compatibility_mode>
+                        <crate_admin_user_notification translate="label comment">
+                            <label>New Admin User Create Notification</label>
+                            <comment>This setting enable notification when new admin user created.</comment>
+                            <frontend_type>select</frontend_type>
+                            <sort_order>10</sort_order>
+                            <source_model>adminhtml/system_config_source_enabledisable</source_model>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </crate_admin_user_notification>
                     </fields>
                 </security>
                 <dashboard translate="label">
diff --git app/code/core/Mage/Customer/Helper/Data.php app/code/core/Mage/Customer/Helper/Data.php
index d99fe64cc12..0852e6e76dd 100644
--- app/code/core/Mage/Customer/Helper/Data.php
+++ app/code/core/Mage/Customer/Helper/Data.php
@@ -274,6 +274,17 @@ class Mage_Customer_Helper_Data extends Mage_Core_Helper_Abstract
         return is_null($passwordCreatedAt) ? $customer->getCreatedAtTimestamp() : $passwordCreatedAt;
     }
 
+    /**
+     * Generate unique token based on customer Id for reset password confirmation link
+     *
+     * @param $customerId
+     * @return string
+     */
+    public function generateResetPasswordLinkCustomerId($customerId)
+    {
+        return md5(uniqid($customerId . microtime() . mt_rand(), true));
+    }
+
     /**
      * Check whether customers registration is allowed
      *
diff --git app/code/core/Mage/Customer/Model/Customer.php app/code/core/Mage/Customer/Model/Customer.php
index 4449942ca01..8df8c8c6fb0 100644
--- app/code/core/Mage/Customer/Model/Customer.php
+++ app/code/core/Mage/Customer/Model/Customer.php
@@ -44,6 +44,7 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
     const EXCEPTION_EMAIL_NOT_CONFIRMED       = 1;
     const EXCEPTION_INVALID_EMAIL_OR_PASSWORD = 2;
     const EXCEPTION_EMAIL_EXISTS              = 3;
+    const EXCEPTION_INVALID_RESET_PASSWORD_LINK_CUSTOMER_ID = 5;
 
     /**
      * Minimum Password Length
@@ -1140,6 +1141,28 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
         return $this->_getResource()->getEntityType();
     }
 
+    /**
+     * Change reset password link customer Id
+     *
+     * Stores new reset password link customer Id
+     *
+     * @param string $newResetPasswordLinkCustomerId
+     * @return Mage_Customer_Model_Customer
+     * @throws Mage_Core_Exception
+     */
+    public function changeResetPasswordLinkCustomerId($newResetPasswordLinkCustomerId)
+    {
+        if (!is_string($newResetPasswordLinkCustomerId) || empty($newResetPasswordLinkCustomerId)) {
+            throw Mage::exception(
+                'Mage_Core',
+                Mage::helper('customer')->__('Invalid password reset customer Id.'),
+                self::EXCEPTION_INVALID_RESET_PASSWORD_LINK_CUSTOMER_ID
+            );
+        }
+        $this->_getResource()->changeResetPasswordLinkCustomerId($this, $newResetPasswordLinkCustomerId);
+        return $this;
+    }
+
     /**
      * Return Entity Type ID
      *
diff --git app/code/core/Mage/Customer/Model/Entity/Customer.php app/code/core/Mage/Customer/Model/Entity/Customer.php
index d7cde9dbc43..88fdc640afd 100644
--- app/code/core/Mage/Customer/Model/Entity/Customer.php
+++ app/code/core/Mage/Customer/Model/Entity/Customer.php
@@ -287,5 +287,26 @@ class Mage_Customer_Model_Entity_Customer extends Mage_Eav_Model_Entity_Abstract
         }
         return $this;
     }
+
+    /**
+     * Change reset password link customer Id
+     *
+     * Stores new reset password link customer Id
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @param string $newResetPasswordLinkCustomerId
+     * @return Mage_Customer_Model_Resource_Customer
+     * @throws Exception
+     */
+    public function changeResetPasswordLinkCustomerId(
+        Mage_Customer_Model_Customer $customer,
+        $newResetPasswordLinkCustomerId
+    ) {
+        if (is_string($newResetPasswordLinkCustomerId) && !empty($newResetPasswordLinkCustomerId)) {
+            $customer->setRpCustomerId($newResetPasswordLinkCustomerId);
+            $this->saveAttribute($customer, 'rp_customer_id');
+        }
+        return $this;
+    }
 }
 
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index fa30ef0277b..f10ead2f33d 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -673,8 +673,12 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 ->setWebsiteId(Mage::app()->getStore()->getWebsiteId())
                 ->loadByEmail($email);
 
-            if ($customer->getId()) {
+            $customerId = $customer->getId();
+            if ($customerId) {
                 try {
+                    $newResetPasswordLinkCustomerId = $this->_getHelper('customer')
+                        ->generateResetPasswordLinkCustomerId($customerId);
+                    $customer->changeResetPasswordLinkCustomerId($newResetPasswordLinkCustomerId);
                     $newPassword = $customer->generatePassword();
                     $customer->changePassword($newPassword, false);
                     $customer->sendPasswordReminderEmail();
@@ -800,6 +804,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             try {
                 $customer->setConfirmation(null);
                 $customer->setPasswordCreatedAt(time());
+                $customer->setRpCustomerId(null);
                 $customer->save();
                 $this->_getSession()->setCustomer($customer)
                     ->addSuccess($this->__('The account information has been saved.'));
@@ -818,6 +823,25 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         $this->_redirect('*/*/edit');
     }
 
+    /**
+     * @return mixed
+     */
+    protected function getCustomerId()
+    {
+        $customerId = $this->getRequest()->getQuery("id");
+        if (strlen($customerId) > 12) {
+            $customerCollection = $this->_getModel('customer/customer')
+                ->getCollection()
+                ->addAttributeToSelect(array('rp_customer_id'))
+                ->addFieldToFilter('rp_customer_id', $customerId);
+            $customerId = count($customerCollection) === 1
+                ? $customerId = $customerCollection->getFirstItem()->getId()
+                : false;
+        }
+
+        return $customerId;
+    }
+
     /**
      * Filtering posted data. Converting localized data if needed
      *
diff --git app/code/core/Mage/Customer/etc/config.xml app/code/core/Mage/Customer/etc/config.xml
index d6b32dd4f99..8961434c5e5 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Customer>
-            <version>1.4.0.0.13.1.2</version>
+            <version>1.4.0.0.13.1.3</version>
         </Mage_Customer>
     </modules>
 
diff --git app/code/core/Mage/Customer/sql/customer_setup/mysql4-upgrade-1.4.0.0.13.1.2-1.4.0.0.13.1.3.php app/code/core/Mage/Customer/sql/customer_setup/mysql4-upgrade-1.4.0.0.13.1.2-1.4.0.0.13.1.3.php
new file mode 100644
index 00000000000..fa456578ee3
--- /dev/null
+++ app/code/core/Mage/Customer/sql/customer_setup/mysql4-upgrade-1.4.0.0.13.1.2-1.4.0.0.13.1.3.php
@@ -0,0 +1,39 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Customer
+ * @copyright Copyright (c) 2006-2018 Magento, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/* @var $installer Mage_Customer_Model_Entity_Setup */
+$installer = $this;
+$installer->startSetup();
+
+// Add reset password link customer Id attribute
+$installer->addAttribute('customer', 'rp_customer_id', array(
+    'type'     => 'varchar',
+    'input'    => 'hidden',
+    'visible'  => false,
+    'required' => false
+));
+
+$installer->endSetup();
diff --git app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
index 8787216919e..1e625c77baf 100644
--- app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
+++ app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
@@ -156,7 +156,7 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
         foreach ($links as $item) {
             $tmpLinkItem = array(
                 'link_id' => $item->getId(),
-                'title' => $item->getTitle(),
+                'title' => $this->escapeHtml($item->getTitle()),
                 'price' => $this->getPriceValue($item->getPrice()),
                 'number_of_downloads' => $item->getNumberOfDownloads(),
                 'is_shareable' => $item->getIsShareable(),
diff --git app/code/core/Mage/Paypal/Model/Express/Checkout.php app/code/core/Mage/Paypal/Model/Express/Checkout.php
index c2f4688aa34..0d439f74e08 100644
--- app/code/core/Mage/Paypal/Model/Express/Checkout.php
+++ app/code/core/Mage/Paypal/Model/Express/Checkout.php
@@ -87,6 +87,11 @@ class Mage_Paypal_Model_Express_Checkout
     protected $_pendingPaymentMessage = '';
     protected $_checkoutRedirectUrl = '';
 
+    /**
+     * @var Mage_Customer_Model_Session
+     */
+    protected $_customerSession;
+
     /**
      * Redirect urls supposed to be set to support giropay
      *
@@ -145,6 +150,7 @@ class Mage_Paypal_Model_Express_Checkout
         } else {
             throw new Exception('Config instance is required.');
         }
+        $this->_customerSession = Mage::getSingleton('customer/session');
     }
 
     /**
@@ -340,6 +346,10 @@ class Mage_Paypal_Model_Express_Checkout
 
     /**
      * Update quote when returned from PayPal
+     * rewrite billing address by paypal
+     * save old billing address for new customer
+     * export shipping address in case address absence
+     *
      * @param string $token
      */
     public function returnFromPaypal($token)
@@ -347,24 +357,33 @@ class Mage_Paypal_Model_Express_Checkout
         $this->_getApi();
         $this->_api->setToken($token)
             ->callGetExpressCheckoutDetails();
+        $quote = $this->_quote;
 
         // import billing address
-        $billingAddress = $this->_quote->getBillingAddress();
+        $billingAddress = $quote->getBillingAddress();
         $exportedBillingAddress = $this->_api->getExportedBillingAddress();
+        $quote->setCustomerEmail($billingAddress->getEmail());
+        $quote->setCustomerPrefix($billingAddress->getPrefix());
+        $quote->setCustomerFirstname($billingAddress->getFirstname());
+        $quote->setCustomerMiddlename($billingAddress->getMiddlename());
+        $quote->setCustomerLastname($billingAddress->getLastname());
+        $quote->setCustomerSuffix($billingAddress->getSuffix());
+        $quote->setCustomerNote($exportedBillingAddress->getData('note'));
         foreach ($exportedBillingAddress->getExportedKeys() as $key) {
             $billingAddress->setDataUsingMethod($key, $exportedBillingAddress->getData($key));
         }
 
         // import shipping address
         $exportedShippingAddress = $this->_api->getExportedShippingAddress();
-        if (!$this->_quote->getIsVirtual()) {
-            $shippingAddress = $this->_quote->getShippingAddress();
+        if (!$quote->getIsVirtual()) {
+            $shippingAddress = $quote->getShippingAddress();
             if ($shippingAddress) {
                 if ($exportedShippingAddress) {
                     foreach ($exportedShippingAddress->getExportedKeys() as $key) {
                         $shippingAddress->setDataUsingMethod($key, $exportedShippingAddress->getData($key));
                     }
                     $shippingAddress->setCollectShippingRates(true);
+                    $shippingAddress->setSameAsBilling(0);
                 }
 
                 // import shipping method
@@ -375,19 +394,22 @@ class Mage_Paypal_Model_Express_Checkout
                         $shippingAddress->setShippingMethod($code)->setCollectShippingRates(true);
                     }
                 }
-                $this->_quote->getPayment()->setAdditionalInformation(self::PAYMENT_INFO_TRANSPORT_SHIPPING_METHOD, $code);
+                $quote->getPayment()->setAdditionalInformation(
+                    self::PAYMENT_INFO_TRANSPORT_SHIPPING_METHOD,
+                    $code
+                );
             }
         }
         $this->_ignoreAddressValidation();
 
         // import payment info
-        $payment = $this->_quote->getPayment();
+        $payment = $quote->getPayment();
         $payment->setMethod($this->_methodType);
         Mage::getSingleton('paypal/info')->importToPayment($this->_api, $payment);
         $payment->setAdditionalInformation(self::PAYMENT_INFO_TRANSPORT_PAYER_ID, $this->_api->getPayerId())
             ->setAdditionalInformation(self::PAYMENT_INFO_TRANSPORT_TOKEN, $token)
         ;
-        $this->_quote->collectTotals()->save();
+        $quote->collectTotals()->save();
     }
 
     /**
@@ -479,10 +501,18 @@ class Mage_Paypal_Model_Express_Checkout
             $this->updateShippingMethod($shippingMethodCode);
         }
 
-        if (!$this->_quote->getCustomerId()) {
-            $this->_quote->setCustomerIsGuest(true)
-                ->setCustomerGroupId(Mage_Customer_Model_Group::NOT_LOGGED_IN_ID)
-                ->setCustomerEmail($this->_quote->getBillingAddress()->getEmail());
+        $isNewCustomer = false;
+        switch ($this->_quote->getCheckoutMethod()) {
+            case Mage_Checkout_Model_Type_Onepage::METHOD_GUEST:
+                $this->_prepareGuestQuote();
+                break;
+            case Mage_Checkout_Model_Type_Onepage::METHOD_REGISTER:
+                $this->_prepareNewCustomerQuote();
+                $isNewCustomer = true;
+                break;
+            default:
+                $this->_prepareCustomerQuote();
+                break;
         }
 
         $this->_ignoreAddressValidation();
@@ -490,6 +520,15 @@ class Mage_Paypal_Model_Express_Checkout
         $service = Mage::getModel('sales/service_quote', $this->_quote);
         $service->submitAll();
         $this->_quote->save();
+
+        if ($isNewCustomer) {
+            try {
+                $this->_involveNewCustomer();
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+        }
+
         $this->_recurringPaymentProfiles = $service->getRecurringPaymentProfiles();
         // TODO: send recurring profile emails
 
@@ -712,4 +751,144 @@ class Mage_Paypal_Model_Express_Checkout
         }
         return '';
     }
+
+    /**
+     * Prepare quote for guest checkout order submit
+     *
+     * @return Mage_Paypal_Model_Express_Checkout
+     */
+    protected function _prepareGuestQuote()
+    {
+        $quote = $this->_quote;
+        $quote->setCustomerId(null)
+            ->setCustomerEmail($quote->getBillingAddress()->getEmail())
+            ->setCustomerIsGuest(true)
+            ->setCustomerGroupId(Mage_Customer_Model_Group::NOT_LOGGED_IN_ID);
+        return $this;
+    }
+
+    /**
+     * Prepare quote for customer registration and customer order submit
+     * and restore magento customer data from quote
+     *
+     * @return Mage_Paypal_Model_Express_Checkout
+     */
+    protected function _prepareNewCustomerQuote()
+    {
+        $quote      = $this->_quote;
+        $billing    = $quote->getBillingAddress();
+        $shipping   = $quote->isVirtual() ? null : $quote->getShippingAddress();
+
+        $customer = $quote->getCustomer();
+        /** @var $customer Mage_Customer_Model_Customer */
+        $customerBilling = $billing->exportCustomerAddress();
+        $customer->addAddress($customerBilling);
+        $billing->setCustomerAddress($customerBilling);
+        $customerBilling->setIsDefaultBilling(true);
+        if ($shipping && !$shipping->getSameAsBilling()) {
+            $customerShipping = $shipping->exportCustomerAddress();
+            $customer->addAddress($customerShipping);
+            $shipping->setCustomerAddress($customerShipping);
+            $customerShipping->setIsDefaultShipping(true);
+        } elseif ($shipping) {
+            $customerBilling->setIsDefaultShipping(true);
+        }
+        /**
+         * @todo integration with dynamica attributes customer_dob, customer_taxvat, customer_gender
+         */
+        if ($quote->getCustomerDob() && !$billing->getCustomerDob()) {
+            $billing->setCustomerDob($quote->getCustomerDob());
+        }
+
+        if ($quote->getCustomerTaxvat() && !$billing->getCustomerTaxvat()) {
+            $billing->setCustomerTaxvat($quote->getCustomerTaxvat());
+        }
+
+        if ($quote->getCustomerGender() && !$billing->getCustomerGender()) {
+            $billing->setCustomerGender($quote->getCustomerGender());
+        }
+
+        Mage::helper('core')->copyFieldset('checkout_onepage_billing', 'to_customer', $billing, $customer);
+        $customer->setEmail($quote->getCustomerEmail());
+        $customer->setPrefix($quote->getCustomerPrefix());
+        $customer->setFirstname($quote->getCustomerFirstname());
+        $customer->setMiddlename($quote->getCustomerMiddlename());
+        $customer->setLastname($quote->getCustomerLastname());
+        $customer->setSuffix($quote->getCustomerSuffix());
+        $customer->setPassword($customer->decryptPassword($quote->getPasswordHash()));
+        $customer->setPasswordHash($customer->hashPassword($customer->getPassword()));
+        $quote->setCustomer($customer)
+            ->setCustomerId(true);
+        $quote->setPasswordHash('');
+
+        return $this;
+    }
+
+    /**
+     * Prepare quote for customer order submit
+     *
+     * @return Mage_Paypal_Model_Express_Checkout
+     */
+    protected function _prepareCustomerQuote()
+    {
+        $quote      = $this->_quote;
+        $billing    = $quote->getBillingAddress();
+        $shipping   = $quote->isVirtual() ? null : $quote->getShippingAddress();
+
+        $customer = $this->getCustomerSession()->getCustomer();
+        if (!$billing->getCustomerId() || $billing->getSaveInAddressBook()) {
+            $customerBilling = $billing->exportCustomerAddress();
+            $customer->addAddress($customerBilling);
+            $billing->setCustomerAddress($customerBilling);
+        }
+        if ($shipping && ((!$shipping->getCustomerId() && !$shipping->getSameAsBilling())
+            || (!$shipping->getSameAsBilling() && $shipping->getSaveInAddressBook()))) {
+            $customerShipping = $shipping->exportCustomerAddress();
+            $customer->addAddress($customerShipping);
+            $shipping->setCustomerAddress($customerShipping);
+        }
+
+        if (isset($customerBilling) && !$customer->getDefaultBilling()) {
+            $customerBilling->setIsDefaultBilling(true);
+        }
+        if ($shipping && isset($customerBilling) && !$customer->getDefaultShipping() && $shipping->getSameAsBilling()) {
+            $customerBilling->setIsDefaultShipping(true);
+        } elseif ($shipping && isset($customerShipping) && !$customer->getDefaultShipping()) {
+            $customerShipping->setIsDefaultShipping(true);
+        }
+        $quote->setCustomer($customer);
+
+        return $this;
+    }
+
+    /**
+     * Involve new customer to system
+     *
+     * @return Mage_Paypal_Model_Express_Checkout
+     */
+    protected function _involveNewCustomer()
+    {
+        $customer = $this->_quote->getCustomer();
+        if ($customer->isConfirmationRequired()) {
+            $customer->sendNewAccountEmail('confirmation');
+            $url = Mage::helper('customer')->getEmailConfirmationUrl($customer->getEmail());
+            $this->getCustomerSession()->addSuccess(
+                Mage::helper('customer')->__('Account confirmation is required. Please, check your e-mail for confirmation link. To resend confirmation email please <a href="%s">click here</a>.', $url)
+            );
+        } else {
+            $customer->sendNewAccountEmail();
+            $this->getCustomerSession()->loginById($customer->getId());
+        }
+        return $this;
+    }
+
+    /**
+     * Get customer session object
+     *
+     * @return Mage_Customer_Model_Session
+     */
+    public function getCustomerSession()
+    {
+        return $this->_customerSession;
+    }
 }
diff --git app/code/core/Zend/Filter/PregReplace.php app/code/core/Zend/Filter/PregReplace.php
index 586c0fe20a0..d6fa2dac0ec 100644
--- app/code/core/Zend/Filter/PregReplace.php
+++ app/code/core/Zend/Filter/PregReplace.php
@@ -21,7 +21,8 @@
 
 /**
  * This class replaces default Zend_Filter_PregReplace because of problem described in MPERF-10057
- * The only difference between current class and original one is overwritten implementation of filter method
+ * The only difference between current class and original one is overwritten implementation of filter method and add new
+ * method _isValidMatchPattern
  *
  * @see Zend_Filter_Interface
  */
@@ -170,14 +171,31 @@ class Zend_Filter_PregReplace implements Zend_Filter_Interface
             #require_once 'Zend/Filter/Exception.php';
             throw new Zend_Filter_Exception(get_class($this) . ' does not have a valid MatchPattern set.');
         }
-        $firstDilimeter = substr($this->_matchPattern, 0, 1);
-        $partsOfRegex = explode($firstDilimeter, $this->_matchPattern);
-        $modifiers = array_pop($partsOfRegex);
-        if ($modifiers != str_replace('e', '', $modifiers)) {
+        if (!$this->_isValidMatchPattern()) {
             throw new Zend_Filter_Exception(get_class($this) . ' uses deprecated modifier "/e".');
         }
 
         return preg_replace($this->_matchPattern, $this->_replacement, $value);
     }
 
+    /**
+     * Method for checking correctness of match pattern
+     *
+     * @return bool
+     */
+    public function _isValidMatchPattern()
+    {
+        $result = true;
+        foreach ((array) $this->_matchPattern as $pattern) {
+            $firstDilimeter = substr($pattern, 0, 1);
+            $partsOfRegex = explode($firstDilimeter, $pattern);
+            $modifiers = array_pop($partsOfRegex);
+            if ($modifiers != str_replace('e', '', $modifiers)) {
+                $result = false;
+                break;
+            }
+        }
+
+        return $result;
+    }
 }
diff --git app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
index 7408669f0e0..2f0de41a37d 100644
--- app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
+++ app/design/adminhtml/default/default/template/bundle/product/edit/bundle/option.phtml
@@ -209,14 +209,16 @@ var optionIndex = 0;
 bOption = new Bundle.Option(optionTemplate);
 //adding data to templates
 <?php foreach ($this->getOptions() as $_option): ?>
-optionIndex = bOption.add(<?php echo $_option->toJson() ?>);
-<?php if ($_option->getSelections()):?>
-    <?php foreach ($_option->getSelections() as $_selection): ?>
-    <?php $_selection->setName($this->escapeHtml($_selection->getName())); ?>
-    <?php $_selection->setSku($this->escapeHtml($_selection->getSku())); ?>
-bSelection.addRow(optionIndex, <?php echo $_selection->toJson() ?>);
-    <?php endforeach; ?>
-<?php endif; ?>
+    <?php $_option->setDefaultTitle($this->escapeHtml($_option->getDefaultTitle())); ?>
+    <?php $_option->setTitle($this->escapeHtml($_option->getTitle())); ?>
+    optionIndex = bOption.add(<?php echo $_option->toJson() ?>);
+    <?php if ($_option->getSelections()):?>
+        <?php foreach ($_option->getSelections() as $_selection): ?>
+        <?php $_selection->setName($this->escapeHtml($_selection->getName())); ?>
+        <?php $_selection->setSku($this->escapeHtml($_selection->getSku())); ?>
+        bSelection.addRow(optionIndex, <?php echo $_selection->toJson() ?>);
+        <?php endforeach; ?>
+    <?php endif; ?>
 <?php endforeach; ?>
 /**
  * Adding event on price type select box of product to hide or show prices for selections
diff --git app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
index b232bf93598..f24a6105d54 100644
--- app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/creditmemo/create/items/renderer.phtml
@@ -49,7 +49,7 @@
     <?php if ($_item->getOrderItem()->getParentItem()): ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
index c8b20fd75b3..c8c6be394fd 100644
--- app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/creditmemo/view/items/renderer.phtml
@@ -49,7 +49,7 @@
     <?php if ($_item->getOrderItem()->getParentItem()): ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
index bdd50096442..1c87f5dbb22 100644
--- app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/invoice/create/items/renderer.phtml
@@ -49,7 +49,7 @@
         <?php $attributes = $this->getSelectionAttributes($_item) ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
index c71df8e7f48..b40e3ee527b 100644
--- app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/invoice/view/items/renderer.phtml
@@ -49,7 +49,7 @@
         <?php $attributes = $this->getSelectionAttributes($_item) ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
index b04f3d83395..9dcabbfd016 100644
--- app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/order/view/items/renderer.phtml
@@ -49,7 +49,7 @@
     <?php if ($_item->getParentItem()): ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
             <td>&nbsp;</td>
diff --git app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
index 76ab3634711..a64e86d1c31 100644
--- app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/shipment/create/items/renderer.phtml
@@ -49,7 +49,7 @@
         <?php $attributes = $this->getSelectionAttributes($_item) ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td>&nbsp;</td>
             <td class="last">&nbsp;</td>
         </tr>
diff --git app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
index c996e7aa9c7..37cab61c7d0 100644
--- app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
+++ app/design/adminhtml/default/default/template/bundle/sales/shipment/view/items/renderer.phtml
@@ -50,7 +50,7 @@
         <?php $attributes = $this->getSelectionAttributes($_item) ?>
         <?php if ($_prevOptionId != $attributes['option_id']): ?>
         <tr>
-            <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+            <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
             <td class="last">&nbsp;</td>
         </tr>
         <?php $_prevOptionId = $attributes['option_id'] ?>
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index ca687fb7a19..efab46f1a8a 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -58,8 +58,8 @@ $_block = $this;
             <th><?php echo Mage::helper('catalog')->__('Image') ?></th>
             <th><?php echo Mage::helper('catalog')->__('Label') ?></th>
             <th><?php echo Mage::helper('catalog')->__('Sort Order') ?></th>
-            <?php foreach ($_block->getImageTypes() as $typeId=>$type): ?>
-            <th><?php echo $type['label'] ?></th>
+            <?php foreach ($_block->getImageTypes() as $typeId => $type): ?>
+                <th><?php echo $this->escapeHtml($type['label']); ?></th>
             <?php endforeach; ?>
             <th><?php echo Mage::helper('catalog')->__('Exclude') ?></th>
             <th class="last"><?php echo Mage::helper('catalog')->__('Remove') ?></th>
diff --git app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
index 299d49c2b11..19bd1894b9c 100644
--- app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/composite/fieldset/downloadable.phtml
@@ -44,7 +44,7 @@
                         <?php endif; ?>
                         <span class="label">
                         <label for="links_<?php echo $_link->getId() ?>">
-                        <?php echo $_link->getTitle() ?>
+                        <?php echo $this->escapeHtml($_link->getTitle()); ?>
                         </label>
                         <?php if ($_link->getSampleFile() || $_link->getSampleUrl()): ?>
                             &nbsp;(<a href="<?php echo $this->getLinkSamlpeUrl($_link) ?>" <?php echo $this->getIsOpenInNewWindow()?'onclick="this.target=\'_blank\'"':''; ?>><?php echo Mage::helper('downloadable')->__('sample') ?></a>)
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
index caf4447b19c..86c83367904 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/creditmemo/name.phtml
@@ -54,7 +54,7 @@
         <dl class="item-options">
             <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
-                <dd><?php echo $_link->getLinkTitle() ?></dd>
+                <dd><?php echo $this->escapeHtml($_link->getLinkTitle()); ?></dd>
             <?php endforeach; ?>
         </dl>
     <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
index 9a15c77b828..96203f8ee98 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/invoice/name.phtml
@@ -54,7 +54,7 @@
         <dl class="item-options">
             <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
-                <dd><?php echo $_link->getLinkTitle() ?> (<?php echo $_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('Unlimited') ?>)</dd>
+                <dd><?php echo $this->escapeHtml($_link->getLinkTitle()); ?> (<?php echo $_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('Unlimited') ?>)</dd>
             <?php endforeach; ?>
         </dl>
     <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
index d032dad80ac..48fff43ab77 100644
--- app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
+++ app/design/adminhtml/default/default/template/downloadable/sales/items/column/downloadable/name.phtml
@@ -54,7 +54,7 @@
         <dl class="item-options">
             <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($this->getLinks()->getPurchasedItems() as $_link): ?>
-                <dd><?php echo $_link->getLinkTitle() ?> (<?php echo $_link->getNumberOfDownloadsUsed() . ' / ' . ($_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('U')) ?>)</dd>
+                <dd><?php echo $this->escapeHtml($_link->getLinkTitle()); ?> (<?php echo $_link->getNumberOfDownloadsUsed() . ' / ' . ($_link->getNumberOfDownloadsBought()?$_link->getNumberOfDownloadsBought():Mage::helper('downloadable')->__('U')) ?>)</dd>
             <?php endforeach; ?>
         </dl>
     <?php endif; ?>
diff --git app/design/frontend/base/default/template/bundle/email/order/items/creditmemo/default.phtml app/design/frontend/base/default/template/bundle/email/order/items/creditmemo/default.phtml
index fce54f00ed1..dde27fd282e 100644
--- app/design/frontend/base/default/template/bundle/email/order/items/creditmemo/default.phtml
+++ app/design/frontend/base/default/template/bundle/email/order/items/creditmemo/default.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td align="left" valign="top" style="padding:3px 9px"><strong><?php echo $attributes['option_label'] ?></strong></td>
+        <td align="left" valign="top" style="padding:3px 9px"><strong><?php echo $this->escapeHtml($attributes['option_label']); ?></strong></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/email/order/items/invoice/default.phtml app/design/frontend/base/default/template/bundle/email/order/items/invoice/default.phtml
index 7f4897f5083..08aa2e197b8 100644
--- app/design/frontend/base/default/template/bundle/email/order/items/invoice/default.phtml
+++ app/design/frontend/base/default/template/bundle/email/order/items/invoice/default.phtml
@@ -44,7 +44,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/email/order/items/order/default.phtml app/design/frontend/base/default/template/bundle/email/order/items/order/default.phtml
index a09f4b2d33b..d88b8d2a6c0 100644
--- app/design/frontend/base/default/template/bundle/email/order/items/order/default.phtml
+++ app/design/frontend/base/default/template/bundle/email/order/items/order/default.phtml
@@ -44,7 +44,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/email/order/items/shipment/default.phtml app/design/frontend/base/default/template/bundle/email/order/items/shipment/default.phtml
index 0b507ba64ee..0ecfe682872 100644
--- app/design/frontend/base/default/template/bundle/email/order/items/shipment/default.phtml
+++ app/design/frontend/base/default/template/bundle/email/order/items/shipment/default.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $attributes['option_label'] ?></em></strong></td>
+        <td align="left" valign="top" style="padding:3px 9px"><strong><em><?php echo $this->escapeHtml($attributes['option_label']); ?></em></strong></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
     </tr>
diff --git app/design/frontend/base/default/template/bundle/sales/order/creditmemo/items/renderer.phtml app/design/frontend/base/default/template/bundle/sales/order/creditmemo/items/renderer.phtml
index 567afdaa06f..a8957dff1b9 100644
--- app/design/frontend/base/default/template/bundle/sales/order/creditmemo/items/renderer.phtml
+++ app/design/frontend/base/default/template/bundle/sales/order/creditmemo/items/renderer.phtml
@@ -45,7 +45,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+        <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/sales/order/invoice/items/renderer.phtml app/design/frontend/base/default/template/bundle/sales/order/invoice/items/renderer.phtml
index 398e351a7a3..6c1135a829b 100644
--- app/design/frontend/base/default/template/bundle/sales/order/invoice/items/renderer.phtml
+++ app/design/frontend/base/default/template/bundle/sales/order/invoice/items/renderer.phtml
@@ -45,7 +45,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+        <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/sales/order/items/renderer.phtml app/design/frontend/base/default/template/bundle/sales/order/items/renderer.phtml
index 21e7815ad2b..dd89ff416dc 100644
--- app/design/frontend/base/default/template/bundle/sales/order/items/renderer.phtml
+++ app/design/frontend/base/default/template/bundle/sales/order/items/renderer.phtml
@@ -43,7 +43,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr<?php if ($_item->getLastRow()) echo 'class="last"'; ?>>
-        <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+        <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
diff --git app/design/frontend/base/default/template/bundle/sales/order/shipment/items/renderer.phtml app/design/frontend/base/default/template/bundle/sales/order/shipment/items/renderer.phtml
index 72b3fa47e16..ac318b2a7b4 100644
--- app/design/frontend/base/default/template/bundle/sales/order/shipment/items/renderer.phtml
+++ app/design/frontend/base/default/template/bundle/sales/order/shipment/items/renderer.phtml
@@ -44,7 +44,7 @@
     <?php $attributes = $this->getSelectionAttributes($_item) ?>
     <?php if ($_prevOptionId != $attributes['option_id']): ?>
     <tr>
-        <td><div class="option-label"><?php echo $attributes['option_label'] ?></div></td>
+        <td><div class="option-label"><?php echo $this->escapeHtml($attributes['option_label']); ?></div></td>
         <td>&nbsp;</td>
         <td>&nbsp;</td>
     </tr>
diff --git app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
index fec4865b7c8..3bb9c189871 100644
--- app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
+++ app/design/frontend/base/default/template/downloadable/catalog/product/links.phtml
@@ -40,7 +40,7 @@
                     <?php endif; ?>
                     <span class="label">
                         <label for="links_<?php echo $_link->getId() ?>">
-                            <?php echo $_link->getTitle() ?>
+                            <?php echo $this->escapeHtml($_link->getTitle()); ?>
                         </label>
                             <?php if ($_link->getSampleFile() || $_link->getSampleUrl()): ?>
                                 &nbsp;(<a href="<?php echo $this->getLinkSamlpeUrl($_link) ?>" <?php echo $this->getIsOpenInNewWindow()?'onclick="this.target=\'_blank\'"':''; ?>><?php echo Mage::helper('downloadable')->__('sample') ?></a>)
diff --git app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
index 8c6c993cc38..cddd6a027f2 100644
--- app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/cart/item/default.phtml
@@ -52,7 +52,7 @@
         <dl class="item-options">
             <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links as $link): ?>
-                <dd><?php echo $link->getTitle() ?></dd>
+                <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
             <?php endforeach; ?>
         </dl>
         <?php endif; ?>
diff --git app/design/frontend/base/default/template/downloadable/checkout/multishipping/item/downloadable.phtml app/design/frontend/base/default/template/downloadable/checkout/multishipping/item/downloadable.phtml
index b377c885344..54e2e6e6611 100644
--- app/design/frontend/base/default/template/downloadable/checkout/multishipping/item/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/multishipping/item/downloadable.phtml
@@ -48,9 +48,9 @@
     <!-- downloadable -->
     <?php if ($links = $this->getLinks()): ?>
     <dl class="item-options">
-        <dt><?php echo $this->getLinksTitle() ?></dt>
+        <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
         <?php foreach ($links as $link): ?>
-            <dd><?php echo $link->getTitle() ?></dd>
+            <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
         <?php endforeach; ?>
     </dl>
     <?php endif; ?>
diff --git app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
index dfdd9ead6d9..ab655d33281 100644
--- app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
+++ app/design/frontend/base/default/template/downloadable/checkout/onepage/review/item.phtml
@@ -50,7 +50,7 @@
         <dl class="item-options">
             <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
             <?php foreach ($links as $link): ?>
-                <dd><?php echo $link->getTitle() ?></dd>
+                <dd><?php echo $this->escapeHtml($link->getTitle()); ?></dd>
             <?php endforeach; ?>
         </dl>
         <?php endif; ?>
diff --git app/design/frontend/base/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml app/design/frontend/base/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
index 84bf7faea27..af97047e1b6 100644
--- app/design/frontend/base/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/email/order/items/creditmemo/downloadable.phtml
@@ -39,7 +39,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
         <dl style="margin:0; padding:0;">
-            <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+            <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
             <?php foreach ($links as $link): ?>
                 <dd style="margin:0; padding:0 0 0 9px;"><?php echo $link->getLinkTitle() ?></dd>
             <?php endforeach; ?>
diff --git app/design/frontend/base/default/template/downloadable/email/order/items/invoice/downloadable.phtml app/design/frontend/base/default/template/downloadable/email/order/items/invoice/downloadable.phtml
index 7d7610d9260..64003357260 100644
--- app/design/frontend/base/default/template/downloadable/email/order/items/invoice/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/email/order/items/invoice/downloadable.phtml
@@ -39,7 +39,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
         <dl style="margin:0; padding:0;">
-            <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+            <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
             <?php foreach ($links as $link): ?>
                 <dd style="margin:0; padding:0 0 0 9px;">
                     <?php echo $link->getLinkTitle() ?>&nbsp;
diff --git app/design/frontend/base/default/template/downloadable/email/order/items/order/downloadable.phtml app/design/frontend/base/default/template/downloadable/email/order/items/order/downloadable.phtml
index b9110c30088..3f3d16bbed9 100644
--- app/design/frontend/base/default/template/downloadable/email/order/items/order/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/email/order/items/order/downloadable.phtml
@@ -39,7 +39,7 @@
         <?php endif; ?>
         <?php if ($links = $this->getLinks()->getPurchasedItems()): ?>
         <dl style="margin:0; padding:0;">
-            <dt><strong><em><?php echo $this->getLinksTitle() ?></em></strong></dt>
+            <dt><strong><em><?php echo $this->escapeHtml($this->getLinksTitle()); ?></em></strong></dt>
             <?php foreach ($links as $link): ?>
                 <dd style="margin:0; padding:0 0 0 9px;">
                     <?php echo $link->getLinkTitle() ?>&nbsp;
diff --git app/design/frontend/base/default/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml app/design/frontend/base/default/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
index 2d9ef3af55a..512b4ddbbee 100644
--- app/design/frontend/base/default/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/sales/order/creditmemo/items/renderer/downloadable.phtml
@@ -54,9 +54,9 @@
         <!-- downloadable -->
         <?php if ($links = $this->getLinks()): ?>
             <dl class="item-options">
-                <dt><?php echo $this->getLinksTitle() ?></dt>
+                <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
                 <?php foreach ($links->getPurchasedItems() as $link): ?>
-                    <dd><?php echo $link->getLinkTitle() ?></dd>
+                    <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
                 <?php endforeach; ?>
             </dl>
         <?php endif; ?>
diff --git app/design/frontend/base/default/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml app/design/frontend/base/default/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
index 22da05dafd0..13fc0c7cc01 100644
--- app/design/frontend/base/default/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/sales/order/invoice/items/renderer/downloadable.phtml
@@ -55,9 +55,9 @@
         <!-- downloadable -->
         <?php if ($links = $this->getLinks()): ?>
             <dl class="item-options">
-                <dt><?php echo $this->getLinksTitle() ?></dt>
+                <dt><?php echo $this->escapeHtml($this->getLinksTitle()); ?></dt>
                 <?php foreach ($links->getPurchasedItems() as $link): ?>
-                    <dd><?php echo $link->getLinkTitle() ?></dd>
+                    <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
                 <?php endforeach; ?>
             </dl>
         <?php endif; ?>
diff --git app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
index 18350b91751..77c6778c754 100644
--- app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
+++ app/design/frontend/base/default/template/downloadable/sales/order/items/renderer/downloadable.phtml
@@ -56,7 +56,7 @@
             <dl class="item-options">
                 <dt><?php echo $this->escapeHtml($this->getLinksTitle()) ?></dt>
                 <?php foreach ($links->getPurchasedItems() as $link): ?>
-                    <dd><?php echo $this->escapeHtml($link->getLinkTitle()) ?></dd>
+                    <dd><?php echo $this->escapeHtml($link->getLinkTitle()); ?></dd>
                 <?php endforeach; ?>
             </dl>
         <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
index a658a61dd22..0ed94e42cfa 100644
--- app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
+++ app/design/frontend/enterprise/default/template/cms/hierarchy/pagination.phtml
@@ -36,7 +36,7 @@
         <?php endif;?>
 
         <?php if ($this->canShowOuter() && $this->canShowFirst()):?>
-            <li><a class="first" title="<?php echo $this->htmlEscape($this->getFirstNode()->getLabel())?>" href="<?php echo $this->getFirstNode()->getUrl()?>"><?php echo $this->getNodeLabel($this->getFirstNode())?></a></li>
+            <li><a class="first" title="<?php echo $this->htmlEscape($this->getFirstNode()->getLabel())?>" href="<?php echo $this->getFirstNode()->getUrl()?>"><?php echo $this->escapeHtml($this->getNodeLabel($this->getFirstNode())); ?></a></li>
         <?php endif;?>
 
         <?php if ($this->canShowPreviousJump()):?>
@@ -56,7 +56,7 @@
         <?php endif;?>
 
         <?php if ($this->canShowOuter() && $this->canShowLast()):?>
-          <li><a class="last" title="<?php echo $this->htmlEscape($this->getLastNode()->getLabel())?>" href="<?php echo $this->getLastNode()->getUrl()?>"><?php echo $this->getNodeLabel($this->getLastNode())?></a><li>
+          <li><a class="last" title="<?php echo $this->htmlEscape($this->getLastNode()->getLabel())?>" href="<?php echo $this->getLastNode()->getUrl()?>"><?php echo $this->escapeHtml($this->getNodeLabel($this->getLastNode())); ?></a><li>
         <?php endif;?>
 
         <?php if ($this->canShowSequence()):?>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index df91e39c36b..a0b34a919dd 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -1192,3 +1192,4 @@
 "website(%s) scope","website(%s) scope"
 "{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
 "You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
+"Disallowed block name for frontend.","Disallowed block name for frontend."
diff --git app/locale/en_US/Mage_Customer.csv app/locale/en_US/Mage_Customer.csv
index ef71e0c6ad4..fa8fb76feae 100644
--- app/locale/en_US/Mage_Customer.csv
+++ app/locale/en_US/Mage_Customer.csv
@@ -189,6 +189,7 @@
 "Invalid customer data","Invalid customer data"
 "Invalid email address.","Invalid email address."
 "Invalid login or password.","Invalid login or password."
+"Invalid password reset customer Id.","Invalid password reset customer Id."
 "Invalid store specified, skipping the record.","Invalid store specified, skipping the record."
 "Last Activity","Last Activity"
 "Last Date Subscribed","Last Date Subscribed"
diff --git app/locale/en_US/template/email/admin_new_user_notification.html app/locale/en_US/template/email/admin_new_user_notification.html
new file mode 100644
index 00000000000..adac7395637
--- /dev/null
+++ app/locale/en_US/template/email/admin_new_user_notification.html
@@ -0,0 +1,36 @@
+<!--@subject New Admin Account {{var user.name}} Created. @-->
+<!--@vars
+{"store url=\"\"":"Store Url",
+"var logo_url":"Email Logo Image Url",
+"var logo_alt":"Email Logo Image Alt",
+"htmlescape var=$user.name":"New Admin Name",
+@-->
+
+<!--@styles
+body,td { color:#2f2f2f; font:11px/1.35em Verdana, Arial, Helvetica, sans-serif; }
+@-->
+
+<body style="background:#F6F6F6; font-family:Verdana, Arial, Helvetica, sans-serif; font-size:12px; margin:0; padding:0;">
+<div style="background:#F6F6F6; font-family:Verdana, Arial, Helvetica, sans-serif; font-size:12px; margin:0; padding:0;">
+    <table cellspacing="0" cellpadding="0" border="0" height="100%" width="100%">
+        <tr>
+            <td align="center" valign="top" style="padding:20px 0 20px 0">
+                <!-- [ header starts here] -->
+                <table bgcolor="FFFFFF" cellspacing="0" cellpadding="10" border="0" width="650" style="border:1px solid #E0E0E0;">
+                    <!-- [ middle starts here] -->
+                    <tr>
+                        <td valign="top">
+                            <h1>New admin account notification.</h1>
+                            <p>A new admin account was created for <b>{{htmlescape var=$user.name}}</b> using email: {{htmlescape var=$user.email}}.</p>
+                            <p>If you have not requested this action, please review the list of administrator accounts in <a href="{{store url=""}}">your store</a>.</p>
+                        </td>
+                    </tr>
+                    <tr>
+                        <td bgcolor="#EAEAEA" align="center" style="background:#EAEAEA; text-align:center;"><center><p style="font-size:12px; margin:0;">Thank you again, <strong>{{var store.getFrontendName()}}</strong></p></center></td>
+                    </tr>
+                </table>
+            </td>
+        </tr>
+    </table>
+</div>
+</body>
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index 0a6875c0ea1..a63edd5a753 100755
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -762,6 +762,18 @@ final class Maged_Controller
      */
     public function dispatch()
     {
+        $baseUrl = Mage::getBaseUrl(
+            Mage_Core_Model_Store::URL_TYPE_LINK, Mage::getSingleton('adminhtml/url')->getSecure()
+        );
+        if (strpos($baseUrl, 'https') === 0) {
+            $request = Mage::app()->getRequest();
+            if (!$request->isSecure()) {
+                Mage::app()->getFrontController()->getResponse()
+                    ->setRedirect(rtrim($baseUrl, '/') . $request->getRequestUri(), 301)->sendResponse();
+                exit;
+            }
+        }
+
         header('Content-type: text/html; charset=UTF-8');
 
         $this->setAction();
diff --git skin/adminhtml/default/enterprise/images/placeholder/thumbnail.jpg skin/adminhtml/default/enterprise/images/placeholder/thumbnail.jpg
new file mode 100644
index 0000000000000000000000000000000000000000..4537aa80b31904bd348d03240a3aad0fc1e531b6
GIT binary patch
literal 1110
zcmex=<NpH&0WUXCHwH#VMg|WcWcYuZ!I^=Xi3x;&fCY$HIapa)SXjB(+1WUFxOjND
zxwyG``Gf>``2_j6xdp@o1cgOJMMZh|#U;c<B!omnML>oyG6VInuyV4pa*FVB^NNrR
z{vTiv<Y4e-NMUAFVqg+vWEN!ne}qAvfq{_~=vt72p@5MI=teen4o)s^pn|Oe3`~s7
z%uFoIAXfub*8=4kSOi&x6b&8OgaZ@Vl?p|S8YeE~P<GmQP&DY`2NmO_q9#r*F>wh=
zDOELf4NWZ*Q!{f5ODks=S2uSLPp{yR(6I1`$f)F$)U@=B%&g*)(z5c3%Btp;*0%PJ
z&aO$5r%atTea6gLixw|gx@`H1m8&*w-m-Pu_8mKS9XfpE=&|D`PM*4S`O4L6*Kgds
z_3+W-Cr_U}fAR9w$4{TXeEs(Q$Io9Ne=#yJL%ap|8JfQYf&OA*VPR%r2l<PUsT_!z
z1zA`X4cUYo1KAS`g_VpNIYgW$F5GyKQ`tD^gJ@FGMJ_QFlZUDwL0$v<j5v=qk>xYE
z#}NLy#lXYN2#h>tK?Zw<zYdGKG#Eg5!2~vcriHU!Dn5R1zF<|*xzBP{^(6spO<t4I
zvzfbUQ$;g6Y!<%BI%B?<W&ZaI3%I8QF-fGzbVV^}Eb4+|&I4xyW_?`p&@S}r`|#QC
z<}Xb<v~a0|n_C7$8~cn82K(=sR!OI{FF0K_D>6mEeUilshE*Hy*j(qF+<M;8K|GSV
z$Kb@O;z-ex{S#l_Te>G{;>zIWU6by;Kcgs7b8k_Dmb><W3X897>u;Y^4=QZ3>gxLG
zb~LAWPTFMu-|K$_u<p`W)W8MBg8N?n3M<|J>&3sVi|&{F)wa6-x1>IbVQclj<sU`E
z?*FZ-&AR&j*Zd=)(e+<neqF$Ae*e|<zpvKk{@ZJ}|I(WH`c?7YSMA;Y>&vhI3|<Ty
zYyYjRzqjm0?e#yJ*TD*N+wayNYS6vtD#8#5#Vsj<Az^nP&NVXH`AX}r2xHv$zy6Q3
z*6s(IarJgb&&9Xw?3T|~@LurZ=5sv9%MiWqKSRj=_o3DKK>Pnqc|CigQNw};zM{-)
z+urYu`Lm$7*+J-@wv|SJ=iOV=t}%1XJwEwH$d>>{R}oa~TXD_xFi%&h2qRC}O2PB@
R?3Qo!MRFC;b&UUS0s!NOuyz0d

literal 0
HcmV?d00001


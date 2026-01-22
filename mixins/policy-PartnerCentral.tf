locals {
  partner_central_permission_sets = [
    {
      name                                = "PartnerCentralFullAccess"
      description                         = "This policy grants full access to AWS Partner Central and related AWS services."
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/AWSPartnerCentralFullAccess"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "PartnerCentralAccountMgmt"
      description                         = "This policy is used by a partner cloud admin to manage IAM roles linked to partner users."
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/PartnerCentralAccountManagementUserRoleAssociation"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "PartnerCentralOpportunityMgmt"
      description                         = "This policy grants full access to manage opportunities in AWS Partner Central."
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/AWSPartnerCentralOpportunityManagement"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "PartnerCentralSandboxAccess"
      description                         = "This policy grants access for developer testing in the Sandbox catalog."
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/AWSPartnerCentralSandboxFullAccess"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "PartnerCentralResourceSnapshot"
      description                         = "This policy provides the ResourceSnapshotJob with permission to read a resource and snapshot it in the target environment."
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/AWSPartnerCentralSellingResourceSnapshotJobExecutionRolePolicy"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "PartnerCentralChannelMgmt"
      description                         = "This policy grants access to manage channel programs and relationships in AWS Partner Central."
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/AWSPartnerCentralChannelManagement"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "PartnerCentralHandshakeMgmt"
      description                         = "This policy grants access to channel handshake approval management activities in AWS Partner Central."
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/AWSPartnerCentralChannelHandshakeApprovalManagement"]
      customer_managed_policy_attachments = []
    },
    {
      name                                = "PartnerCentralMarketingMgmt"
      description                         = "This policy grants access to manage marketing activities and campaigns in AWS Partner Central."
      relay_state                         = ""
      session_duration                    = ""
      tags                                = {}
      inline_policy                       = ""
      policy_attachments                  = ["arn:${local.aws_partition}:iam::aws:policy/AWSPartnerCentralMarketingManagement"]
      customer_managed_policy_attachments = []
    }
  ]
}

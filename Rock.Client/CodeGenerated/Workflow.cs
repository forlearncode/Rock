//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by the Rock.CodeGeneration project
//     Changes to this file will be lost when the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------
// <copyright>
// Copyright by the Spark Development Network
//
// Licensed under the Rock Community License (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.rockrms.com/license
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// </copyright>
//
using System;
using System.Collections.Generic;


namespace Rock.Client
{
    /// <summary>
    /// Base client model for Workflow that only includes the non-virtual fields. Use this for PUT/POSTs
    /// </summary>
    public partial class WorkflowEntity
    {
        /// <summary />
        public int Id { get; set; }

        /// <summary />
        public DateTime? ActivatedDateTime { get; set; }

        /// <summary />
        public DateTime? CompletedDateTime { get; set; }

        /// <summary />
        public string Description { get; set; }

        /// <summary />
        public Guid? ForeignGuid { get; set; }

        /// <summary />
        public string ForeignKey { get; set; }

        /// <summary />
        public int? InitiatorPersonAliasId { get; set; }

        /// <summary />
        public bool IsProcessing { get; set; }

        /// <summary />
        public DateTime? LastProcessedDateTime { get; set; }

        /// <summary />
        public string Name { get; set; }

        /// <summary />
        public string Status { get; set; }

        /// <summary />
        public int WorkflowIdNumber { get; set; }

        /// <summary />
        public int WorkflowTypeId { get; set; }

        /// <summary />
        public DateTime? CreatedDateTime { get; set; }

        /// <summary />
        public DateTime? ModifiedDateTime { get; set; }

        /// <summary />
        public int? CreatedByPersonAliasId { get; set; }

        /// <summary />
        public int? ModifiedByPersonAliasId { get; set; }

        /// <summary />
        public Guid Guid { get; set; }

        /// <summary />
        public int? ForeignId { get; set; }

        /// <summary>
        /// Copies the base properties from a source Workflow object
        /// </summary>
        /// <param name="source">The source.</param>
        public void CopyPropertiesFrom( Workflow source )
        {
            this.Id = source.Id;
            this.ActivatedDateTime = source.ActivatedDateTime;
            this.CompletedDateTime = source.CompletedDateTime;
            this.Description = source.Description;
            this.ForeignGuid = source.ForeignGuid;
            this.ForeignKey = source.ForeignKey;
            this.InitiatorPersonAliasId = source.InitiatorPersonAliasId;
            this.IsProcessing = source.IsProcessing;
            this.LastProcessedDateTime = source.LastProcessedDateTime;
            this.Name = source.Name;
            this.Status = source.Status;
            this.WorkflowIdNumber = source.WorkflowIdNumber;
            this.WorkflowTypeId = source.WorkflowTypeId;
            this.CreatedDateTime = source.CreatedDateTime;
            this.ModifiedDateTime = source.ModifiedDateTime;
            this.CreatedByPersonAliasId = source.CreatedByPersonAliasId;
            this.ModifiedByPersonAliasId = source.ModifiedByPersonAliasId;
            this.Guid = source.Guid;
            this.ForeignId = source.ForeignId;

        }
    }

    /// <summary>
    /// Client model for Workflow that includes all the fields that are available for GETs. Use this for GETs (use WorkflowEntity for POST/PUTs)
    /// </summary>
    public partial class Workflow : WorkflowEntity
    {
        /// <summary />
        public ICollection<WorkflowActivity> Activities { get; set; }

        /// <summary />
        public PersonAlias InitiatorPersonAlias { get; set; }

        /// <summary />
        public string WorkflowId { get; set; }

    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DataAccessLayer
{
    public class DataFilterModel
    {
        public string Depth { get; set; }
        public string Gear { get; set; }
        public string Cargo1 { get; set; }
        public string Cargo2 { get; set; }
        public string Cargo3 { get; set; }
        public string OtherCargo { get; set; }
        public string Type1 { get; set; }
        public string Type2 { get; set; }
        public string Type3 { get; set; }
    }
}

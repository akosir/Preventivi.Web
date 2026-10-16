using System.ComponentModel.DataAnnotations;

namespace Preventivi.Web.UI.Modules.Account;

public sealed class LoginFormModel
{
    [Required(ErrorMessage = "Inserire lo username.")]
    [Display(Name = "Username")]
    public string Username { get; set; } = "";

    [Required(ErrorMessage = "Inserire la password.")]
    [DataType(DataType.Password)]
    [Display(Name = "Password")]
    public string Password { get; set; } = "";
}

using SetnjaPasaSarajevo.Model.Requests;
using FluentValidation;

namespace SetnjaPasaSarajevo.Services.Validators
{
    public class ReservationUpdateValidator : AbstractValidator<ReservationUpdateRequest>
    {
        public ReservationUpdateValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("First name is required.")
                .MaximumLength(50).WithMessage("First name cannot exceed 50 characters.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Last name is required.")
                .MaximumLength(50).WithMessage("Last name cannot exceed 50 characters.");

            RuleFor(x => x.Address)
                .NotEmpty().WithMessage("Address is required.")
                .MaximumLength(255).WithMessage("Address cannot exceed 255 characters.");

            RuleFor(x => x.PhoneNumber)
                .NotEmpty().WithMessage("Phone number is required.")
                .MaximumLength(20).WithMessage("Phone number cannot exceed 20 characters.");

            RuleFor(x => x.PetName)
                .NotEmpty().WithMessage("Pet name is required.")
                .MaximumLength(100).WithMessage("Pet name cannot exceed 100 characters.");

            RuleFor(x => x.PetType)
                .NotEmpty().WithMessage("Pet type is required.")
                .MaximumLength(50).WithMessage("Pet type cannot exceed 50 characters.");

            RuleFor(x => x.Notes)
                .MaximumLength(500).WithMessage("Notes cannot exceed 500 characters.")
                .When(x => !string.IsNullOrEmpty(x.Notes));

            RuleFor(x => x.ReservationDateTime)
                .NotEmpty().WithMessage("Reservation date and time is required.")
                .GreaterThan(System.DateTime.UtcNow).WithMessage("Reservation date and time must be in the future.");
        }
    }
}

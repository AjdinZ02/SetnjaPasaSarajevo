using SetnjaPasaSarajevo.Model.Requests;
using FluentValidation;

namespace SetnjaPasaSarajevo.Services.Validators
{
    public class PetInsertValidator : AbstractValidator<PetInsertRequest>
    {
        public PetInsertValidator()
        {
            RuleFor(x => x.PetName)
                .NotEmpty().WithMessage("Pet name is required.")
                .MaximumLength(100).WithMessage("Pet name cannot exceed 100 characters.");

            RuleFor(x => x.Age)
                .GreaterThanOrEqualTo(0).WithMessage("Pet age must be zero or greater.");

            RuleFor(x => x.PetType)
                .NotEmpty().WithMessage("Pet type is required.")
                .MaximumLength(50).WithMessage("Pet type cannot exceed 50 characters.");

            RuleFor(x => x.Notes)
                .MaximumLength(250).WithMessage("Notes cannot exceed 250 characters.")
                .When(x => !string.IsNullOrEmpty(x.Notes));
        }
    }
}

using SetnjaPasaSarajevo.Model.Requests;
using FluentValidation;

namespace SetnjaPasaSarajevo.Services.Validators
{
    public class ReservationInsertValidator : AbstractValidator<ReservationInsertRequest>
    {
        public ReservationInsertValidator()
        {
           RuleFor(x => x.UserId)
            .NotEmpty();

        RuleFor(x => x.PetId)
            .NotEmpty();

RuleFor(x => x.TimeSlotId)
    .NotEmpty()
    .WithMessage("TimeSlot is required");

RuleFor(x => x.PetName)
    .NotEmpty();

RuleFor(x => x.PetType)
    .NotEmpty();
        }
    }
}
